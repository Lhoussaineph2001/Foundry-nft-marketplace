// Foundry FrameWork

## TEST

1. forge test 
2. forge test --mt function_name

- Tip
    'getCode' cheatcode to deploy contracts with incompatible Solidity versions

# EVENTS

- event Transfer(address indexed from, address indexed to, uint256 amount);
1. vm.expectEmit(true, true, false, true);
2. emit Transfer(address(this), address(1337), 1337);

contract EmitContractTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    function test_ExpectEmit() public {
        ExpectEmit emitter = new ExpectEmit();
        // Check that topic 1, topic 2, and data are the same as the following 
emitted event.
        // Checking topic 3 here doesn't matter, because `Transfer` only has 2 
indexed topics.
        vm.expectEmit(true, true, false, true);
        // The event we expect
        emit Transfer(address(this), address(1337), 1337);
        // The event we get
        emitter.t();
    }
    function test_ExpectEmit_DoNotCheckData() public {
        ExpectEmit emitter = new ExpectEmit();
        // Check topic 1 and topic 2, but do not check data
        vm.expectEmit(true, true, false, false);
        // The event we expect
        emit Transfer(address(this), address(1337), 1338);
        // The event we get
        // t() function has event 
        emitter.t();
    }
 }

# PRANK

1. vm.prank()
2. vm.startPrank()
// set up a prank as Alice with 100 ETH balance
3.  hoax(alice, 100 ether);
// expect an arithmetic error on the next call (e.g. underflow)
4. vm.expectRevert(stdError.arithmeticError);
// find the variable `score` in the contract `game`
// and change its value to 10
5. stdstore
    .target(address(game))
    .sig(game.score.selector)
    .checked_write(10);

# TRACES

 [<Gas Usage>] <Contract>::<Function>(<Parameters>)
 ├─ [<Gas Usage>] <Contract>::<Function>(<Parameters>)
 │   └─ ← <Return Value>
 └─ ← <Return Value>

# Fork Testing
 Forge supports testing in a forked environment with two different approaches:
 Forking Mode — use a single fork for all your tests via the 
1. forge test --fork-url
2. Forking Cheatcodes — create, select, and manage multiple forks directly in Solidity
 test code via
3.  forge test --fork-url <your_rpc_url> --etherscan-api-key 
<your_etherscan_api_key>

### frok Cheatcodes :
 contract ForkTest is Test {
    // the identifiers of the forks
    uint256 mainnetFork;
    uint256 optimismFork;
    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url 
if need
    //inside your .env file e.g:
    //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    //string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    //string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");
    // create two _different_ forks during setup
    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);
    }
    // demonstrate fork ids are unique
    function testForkIdDiffer() public {
        assert(mainnetFork != optimismFork);
    }
    // select a specific fork
    function testCanSelectFork() public {
        // select the fork
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
        // from here on data is fetched from the `mainnetFork` if the EVM 
requests it and written to the storage of `mainnetFork`
    }
    // manage multiple forks in the same test
    function testCanSwitchForks() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
        vm.selectFork(optimismFork);
        assertEq(vm.activeFork(), optimismFork);
    }
    // forks can be created at all times
    function testCanCreateAndSelectForkInOneStep() public {
        // creates a new fork and also selects it
        uint256 anotherFork = vm.createSelectFork(MAINNET_RPC_URL);
        assertEq(vm.activeFork(), anotherFork);
    }
    // set `block.number` of a fork
    function testCanSetForkBlockNumber() public {
    vm.selectFork(mainnetFork);
    vm.rollFork(1_337_000);
    assertEq(block.number, 1_337_000);
    }
    }


