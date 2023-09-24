const express = require('express');
const { ethers } = require("ethers");

const Config = {
    intentActionModule: '0x9Cdf3cef6932c2E4BBE5A724e1176DeFEF1A4f39',
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
    const nowMs = Date.now();
    const resolved = [];
    for (const [k, intent] of Object.entries(db)) {
        if (nowMs >= intent.deadline) {
            console.log('Resolve intent now', intent);
            if (intent.offers) {
                // TODO: trigger
                //   intentMgr.swap(seller, sellToken, sellAmount, buyer, buyToken, buyAmount)
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