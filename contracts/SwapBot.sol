pragma solidity 0.6.6;

import "./Credits.sol";

contract SwapBot {
    using SafeMath for uint256;

    address public feeAccount;                                                  // the account that receives exchange fees
    uint256 public feePercent;                                                  // the fee percentage
    address constant ETHER = address(0);                                        // store Ether in credits mapping with blank address
    mapping(address => mapping(address => uint256)) public creditsAvailable;    // ether & credits available
    mapping(uint256 => _Order) public orders;                                   // storage of the different orders
    uint256 public orderCount;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Order(
        uint256 id,
        address user,       
        address tokenGet, 
        uint256 amountGet,     
        address tokenGive,  
        uint256 amountGive,    
        uint256 timestamp
    );
    event Cancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event Trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address userFill,
        uint256 timestamp
    );


    // template to add orders
    struct _Order {
        uint256 id; 
        address user;           // the person who create the order
        address tokenGet;       // token user wants to purchase
        uint256 amountGet;      // the amount of the token they want to get
        address tokenGive;      // the token they're going to use in the trade
        uint256 amountGive;     // the amount of the token they're going to trade
        uint256 timestamp;      // time of when the order was created
    }

    constructor (address _feeAccount, uint256 _feePercent) public {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    // Fallback: reverts if Ether is sent to this smart contract by mistake
    fallback() external {
        revert();
    }

    function depositEther() payable public {
        creditsAvailable[ETHER][msg.sender] = creditsAvailable[ETHER][msg.sender].add(msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, creditsAvailable[ETHER][msg.sender]);
    }

    function withdrawEther(uint _amount) public {
        require(creditsAvailable[ETHER][msg.sender] >= _amount);
        creditsAvailable[ETHER][msg.sender] = creditsAvailable[ETHER][msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, creditsAvailable[ETHER][msg.sender]);
    }

    function depositCredits(address _token, uint _amount) public {
        require(_token != ETHER);
        require(Credits(_token).transferFrom(msg.sender, address(this), _amount));
        creditsAvailable[_token][msg.sender] = creditsAvailable[_token][msg.sender].add(_amount);
        emit Deposit(_token, msg.sender, _amount, creditsAvailable[_token][msg.sender]);
    }

    function withdrawCredits(address _token, uint256 _amount) public {
        require(_token != ETHER);
        require(creditsAvailable[_token][msg.sender] >= _amount);
        creditsAvailable[_token][msg.sender] = creditsAvailable[_token][msg.sender].sub(_amount);
        require(Credits(_token). transfer(msg.sender, _amount));
        emit Withdraw(_token, msg.sender, _amount, creditsAvailable[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns (uint256) {
        return creditsAvailable[_token][_user];
    }

    function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
        emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
    }

    function cancelOrder(uint256 _id) public {
        _Order storage _order = orders[_id];
        require(address(_order.user) == msg.sender);        // order must be the user's
        require(_order.id == _id);                          // the order must exist
        orderCancelled[_id] = true;
        emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
    }

    function fillOrder(uint256 _id) public {
        require(_id > 0 && _id <= orderCount);
        require(!orderFilled[_id]);
        require(!orderCancelled[_id]);
        _Order storage _order = orders[_id];
        _trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
        orderFilled[_order.id] = true;
    }

    function _trade(uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
        // Fee paid by the user that fills the order, a.k.a. msg.sender.
        uint256 _feeAmount = _amountGet.mul(feePercent).div(100); // 10% fee

        // Execute trade
        creditsAvailable[_tokenGet][msg.sender] = creditsAvailable[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
        creditsAvailable[_tokenGet][_user] = creditsAvailable[_tokenGet][_user].add(_amountGet);
        creditsAvailable[_tokenGet][feeAccount] = creditsAvailable[_tokenGet][feeAccount].add(_feeAmount);
        creditsAvailable[_tokenGive][_user] = creditsAvailable[_tokenGive][_user].sub(_amountGive);
        creditsAvailable[_tokenGive][msg.sender] = creditsAvailable[_tokenGive][msg.sender].add(_amountGive);

        emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);
    }
}
