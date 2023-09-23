#!/bin/bash

mkdir -p ./contracts/modules/act/intent
mkdir -p ./test/modules/act
mkdir -p ./foundry-scripts
rsync -a ../lens-core/contracts/modules/act/intent ./contracts/modules/act/intent
rsync -a ../lens-core/test/modules/act/IntentAction.t.sol ./test/modules/act/IntentAction.t.sol
rsync -a ../lens-core/foundry-scripts/DeployIntentAction.s.sol ./foundry-scripts/DeployIntentAction.s.sol