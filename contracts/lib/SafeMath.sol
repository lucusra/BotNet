//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface ERC20 {
    function totalSupply() external view returns (uint flareTokenTotalSupply);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function viewAllowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address _to, uint _amount) external returns (bool success);
    function approve(address _spender, uint _amount) external returns (bool success);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool success);

// // Are optional 
//      function symbol() external view returns (string memory);
//      function name() external view returns (string memory);
//      function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }
}

contract FlareToken is ERC20 {
    using SafeMath for uint256;

	string private _name = "Flare Token";
    string private _symbol = "FLARE";
    uint8 private _decimals = 18;                       
    uint256 private _totalSupply;                                                                                    

    address payable owner;

    struct Checkpoint {
        uint value;
        uint fromBlock;
    }

    struct Delegation {
        uint power;
        uint fromblock;
        uint totalDelegations;
    }

    mapping(address => Checkpoint[]) balances;
    mapping(address => mapping(address => Checkpoint[])) allowances;
    mapping(address => Delegation[]) delegations;


    constructor() {    
        _totalSupply = 1000000 * (18**10);   // 1 mil tokens
        owner = msg.sender;
        balances[owner][0].value = _totalSupply;
        balances[owner][0].fromBlock = block.number;
    }


    // ----------------------------------
    //          ERC20 Functions
    // ----------------------------------

    function totalSupply() override external view returns (uint flareTokenTotalSupply) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return balances[tokenOwner][balances[tokenOwner].length].value;
    }

    function viewAllowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowances[spender][tokenOwner][allowances[spender][tokenOwner].length].value;
    }

    function transfer(address _to, uint _amount) override external returns (bool success) {
        require(
            balances[msg.sender][balances[msg.sender].length].value != 0, 
            "ERROR: Insufficient token balance"
            );
        performTransfer(msg.sender, _to, _amount);
        return success;
    }

    function approve(address _spender, uint _amount) override external returns (bool success) {
        require(
            _spender != msg.sender, 
            "ERROR: Unable to give your own address your allowance"
            );
        performApprove(msg.sender, _spender, _amount);
        return success;
    }

    function transferFrom(address _from, address _to, uint _amount) override external returns (bool success) {
        uint userAllowance = allowances[msg.sender][_from][allowances[msg.sender][_from].length].value;
        require(
            userAllowance >= _amount,
            "ERROR: Insufficient allowance amount"
            );
        performApprove(_from, msg.sender, userAllowance.sub(_amount));
        performTransfer(_from, _to, _amount);
        return success;
    }


    // ----------------------------------
    //           Extra API's
    // ----------------------------------

    // function delegate(address _address, uint _percentage) external {

    // }

    // function _delegate(address _delegator, address _delegatee, uint _tokenAmount) internal returns(string memory){
    //     require(delegations[_delegator][delegations[_delegator].length].power != 0, "ERROR: Insufficient power to delegate");
    //     require(delegations[_delegator][delegations[_delegator].length].totalDelegations <= 5, "ERROR: Maximum delegations met (5)");

    //     uint userPower = balanceOf(_delegator);
    //     uint updatedPower = (delegations[_delegator][delegations[_delegator].length].power).mod(_percentage);
        
    // }

    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {
        if (balances[msg.sender].length == 0) return 0;

        // Shortcut for the actual value
        if (_blockNumber >= balances[_owner][balances[_owner].length-1].fromBlock)
            return balances[_owner][balances[_owner].length-1].value;
        if (_blockNumber < balances[_owner][0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = balances[_owner].length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (balances[_owner][mid].fromBlock<=_blockNumber) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return balances[_owner][min].value;
    }

    function performTransfer(address _from, address _to, uint _amount) internal {
        uint newValue;
        uint newBlock;

        newValue = balances[_from][balances[_from].length].value.sub(_amount);
        newBlock = block.number;
        balances[_from].push(Checkpoint(newValue, newBlock));

        newValue = balances[_to][balances[_to].length].value.sub(_amount);
        newBlock = block.number; 
        balances[_to].push(Checkpoint(newValue, newBlock));
    
        emit Transfer(_from, _to, _amount);
    }

    function performApprove(address _approver, address _spender, uint _amount) internal {
        allowances[_spender][_approver].push(Checkpoint(_amount, block.number));
        emit Approval(_approver, _spender, _amount);
    }
}
