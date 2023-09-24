const express = require('express');
const { ethers } = require("ethers");
const { createWalletClient, http, getContract } = require('viem');
const { privateKeyToAccount } = require('viem/accounts');
const { polygonMumbai } = require('viem/chains');
const { parseAbi } = require('viem');

const abi = parseAbi([
  'function fill(address seller, uint256 amountToSell, address buyer, uint256 amountToBuy) external',
]);

const Config = {
    intentActionModule: '0x8d0cd56c2fa3f4dcbf7060edfed5798ae3ce34eb',
}

const PublicationActionParams = `tuple(${
    [
        'uint256 publicationActedProfileId',
        'uint256 publicationActedId',
        'uint256 actorProfileId',
        'uint256[] referrerProfileIds',
        'uint256[] referrerPubIds',
        'address actionModuleAddress',
        'bytes actionModuleData',
    ].join(',')
})`;
const FillAction = `tuple(uint256 amount)`;
const PreviewDomainSeparator = '0x5af01eb037664be43588292ec353207d1d8ddadd14e94d7a199d230bbc0de228';
const TypeHashAct = ethers.utils.keccak256('Act(uint256 publicationActedProfileId,uint256 publicationActedId,uint256 actorProfileId,uint256[] referrerProfileIds,uint256[] referrerPubIds,address actionModuleAddress,bytes actionModuleData,uint256 nonce,uint256 deadline)');



var app = express()

app.get('/', async function(req, res){
  res.send('Hello World');
});

// post: /add-intent
// { owner: account, sellAmount, sellToken, buyToken, deadline }

const db = {};

app.post('/add-intent', async function(req, res) {
    const intent = req.body;
    db[intent.owner] = { ...intent, offers: [] };
    res.send({ status: 'ok' });
})

// post: /offer
// { owner: account, filler: account, buyAmount }

app.post('/offer', async function(req, res) {
    const offer = req.body;
    if (!db[offer.owner]) {
        res.send({ status: 'err', error: 'intent not found' });
    }

    db[offer.owner].offers.push({ ...offer });
    db[offer.owner].offers.sort((a, b) => {
        const diff = BigInt(a.buyAmount) - BigInt(b.buyAmount);
        if (diff < 0n) {
            return 1;
        } else if (diff == 0) {
            return 0;
        } else {
            return -1;
        }
    });
    res.send({ status: 'ok' });
});

// every 5s: check intents

async function tryResolve() {
    const client = createWalletClient({
        chain: polygonMumbai,
        transport: http()
    });
    const deployer = privateKeyToAccount(process.env.MNEMONIC);
    const contract = getContract({
        abi,
        address: Config.intentActionModule,
        client: client,
        walletClient: client,
    })

    const nowMs = Date.now();
    const resolved = [];
    for (const [k, intent] of Object.entries(db)) {
        if (nowMs >= intent.deadline) {
            console.log('Resolve intent now', intent);
            if (intent.offers) {
                // trigger
                const offer = intent.offers[0];
                const hash = await contract.write.fill([intent.owner, intent.sellAmount, offer.filler, offer.buyAmount]);
                console.log('Filled tx:', hash);
            } else {
                // TODO: cancel
            }
            resolved.push(k);
        }
    }
    for (const k of resolved) {
        delete db[k];
    }
}

function sleep(ms) {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    });
}

async function loopMain() {
    while(true) {
        await tryResolve();
        await sleep(3000)
    }
}

app.get('/test', async function(req, res) {
    const encodedParams = ethers.utils.defaultAbiCoder.encode([PublicationActionParams], [[
        '0x01', '0x0123',  // target pub
        '0x02',  //my profile id
        [], [],
        Config.intentActionModule,
        ethers.utils.defaultAbiCoder.encode(
            [FillAction],
            [[ethers.utils.parseUnits('100', 'ether')]]
        ),
    ]]);

    console.log({encodedParams});

    // console.log('resultTypedData', resultTypedData);

    res.send('done');
});

app.listen(3000, () => console.log('Start listening'))

loopMain()
.then(process.exit)
.catch(err => console.error(err))
.finally(() => process.exit(-1))