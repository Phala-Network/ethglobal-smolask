# Simple Mock Intent Pool

## Run on mumbai

```bash
(source ../.env; MNEMONIC="$MNEMONIC" node .)
```

## GET `/intents`

Return:

```js
{
    // Map: owner => intent details
    '0x....': {
        // Seller's address
        owner: '0x....',
        // Amount in string (wei)
        sellAmount: '1000000',
        // Selling token address
        sellToken: '0x....,
        // Buying token address
        buyToken: '0x....',
        // Deadline in timestampe ms
        deadline: 1695529160688,
        // Available offers, sorted in desc order
        offers: [
            {
                // Buyer's address
                filler: '0x....',
                // Amount in string (wei)
                buyAmount: '200000',
            }
        ]
    },
    // ...
]
```

## POST `/add-intent`

Input:

```js
{
    // Seller's address
    owner: '0x....',
    // Amount in string (wei)
    sellAmount: '1000000',
    // Selling token address
    sellToken: '0x....,
    // Buying token address
    buyToken: '0x....',
    // Deadline in timestampe ms
    deadline: 1695529160688,
}
```

Return:

```js
{ status: 'ok' }
```

## POST `/offer`

Input:

```js
{
    // The account of the swap intent owner (to fill)
    owner: '0x....',
    // Buyer's address
    filler: '0x....',
    // Amount in string (wei)
    buyAmount: '200000',
}
```

Return:

```js
{ status: 'ok' }
```