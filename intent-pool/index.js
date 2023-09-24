const express = require('express');
const { ethers } = require("ethers");
const { createWalletClient, http, getContract } = require('viem');
const { mnemonicToAccount } = require('viem/accounts');
const { polygonMumbai } = require('viem/chains');
const { parseAbi } = require('viem');

const abi = parseAbi([
  'function fill(address seller, uint256 amountToSell, address buyer, uint256 amountToBuy) external',
]);

const Config = {
    intentActionModule: '0x8d0cd56c2fa3f4dcbf7060edfed5798ae3ce34eb',
}

// const PublicationActionParams = `tuple(${
//     [
//         'uint256 publicationActedProfileId',
//         'uint256 publicationActedId',
//         'uint256 actorProfileId',
//         'uint256[] referrerProfileIds',
//         'uint256[] referrerPubIds',
//         'address actionModuleAddress',
//         'bytes actionModuleData',
//     ].join(',')
// })`;
// const FillAction = `tuple(uint256 amount)`;
// const PreviewDomainSeparator = '0x5af01eb037664be43588292ec353207d1d8ddadd14e94d7a199d230bbc0de228';
// const TypeHashAct = ethers.utils.keccak256('Act(uint256 publicationActedProfileId,uint256 publicationActedId,uint256 actorProfileId,uint256[] referrerProfileIds,uint256[] referrerPubIds,address actionModuleAddress,bytes actionModuleData,uint256 nonce,uint256 deadline)');



var app = express()

app.get('/', async function(req, res){
  res.send('Hello World');
});

// post: /add-intent
// { owner: account, sellAmount, sellToken, buyToken, deadline }

const db = {};

function handleAddIntent(intent) {
    console.log({intent});
    db[intent.owner] = { ...intent, offers: [] };
}

app.post('/add-intent', async function(req, res) {
    const intent = req.body;
    handleAddIntent(intent);
    res.send({ status: 'ok' });
})

// post: /offer
// { owner: account, filler: account, buyAmount }

function handleOffer(offer) {
    console.log({offer});
    if (!db[offer.owner]) {
        return { status: 'err', error: 'intent not found' };
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

    console.log('Sorted offers:', db[offer.owner].offers);
    return { status: 'ok' };
}

app.post('/offer', async function(req, res) {
    const offer = req.body;
    res.send(handleOffer(offer));
});

app.get('/intents', async function(req, res) {
    res.send(db);
})

// every 5s: check intents

async function tryResolve() {
    const client = createWalletClient({
        chain: polygonMumbai,
        transport: http()
    });
    const deployer = mnemonicToAccount(process.env.MNEMONIC);
    const walletClient = createWalletClient({
        account: deployer,
        chain: polygonMumbai,
        transport: http()
      })
    const contract = getContract({
        abi,
        address: Config.intentActionModule,
        client,
        walletClient,
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

app.get('/test-e2e', async function(req, res) {
    const nowMs = Date.now();
    const accounts = [
        '0x4d29C9e21990420a33F3409f9772A6cE4e92A39c',
        '0x01bF2d1fD7c86864Ac9a5dfeA21161E57A864e51',
        '0xEeBC88165E26A014827A2aa7838049082e920124',
    ];
    const e18 = '000000000000000000';
    handleAddIntent({
        owner: accounts[0],
        sellAmount: '1' + e18,
        sellToken: 'ommitted',
        buyToken: 'ommitted',
        deadline: nowMs + 2000,
    });
    handleOffer({
        owner: accounts[0],
        filler: accounts[1],
        buyAmount: '4' + e18,
    });
    handleOffer({
        owner: accounts[0],
        filler: accounts[1],
        buyAmount: '5' + e18,
    });
    res.send({ status: 'ok' });
});

app.listen(3000, () => console.log('Start listening: http://localhost:3000'))

loopMain()
.then(process.exit)
.catch(err => console.error(err))
.finally(() => process.exit(-1))