pragma solidity ^0.4.18;

contract ERC20Interface
{
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is ERC20Interface
{
    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
      return allowed[_owner][_spender];
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }

    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
}

// For the test

//name this contract whatever you'd like
contract ContractERC20 is ERC20
{
	address public thisContract;
    uint8  public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public name;                   //fancy name: eg Simon Bucks
    string public symbol;                 //An identifier: eg SBX
    string public version = 'H1.0';       //human 0.1 standard. Just an arbitrary versioning scheme.

   //make sure this function name matches the contract name above. So if you're token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of ERC20Token
    function ContractERC20() public payable {
        balances[msg.sender] = 100000;               // Give the creator all initial tokens (100000 for example)
        totalSupply = 100000;                        // Update total supply (100000 for example)
        name = "NAME OF YOUR TOKEN HERE";            // Set the name for display purposes
        decimals = 0;                                // Amount of decimals for display purposes
        symbol = "SYM";                              // Set the symbol for display purposes
        thisContract = this;
    }

    function _transfer(address _from, address _to, uint256 _value) public returns (bool) {
        if (balances[_from] >= _value && _value > 0) {
            balances[_from] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function() public payable {}
}

/* Ownable contract */
contract Owner {
    address public owner;

    modifier onlyOwner()
    {
        require(owner == msg.sender);
        _;
    }

    function Owner(address _owner) public
    {
        owner = _owner;
    }

    function changeOwner(address _owner) onlyOwner payable public
    {
        owner = _owner;
    }
}

/* Admins contract */
contract Admin is Owner
{
    mapping (address => bool) public admins;

    modifier onlyAdmin()
    {
        require(admins[msg.sender]);
        _;
    }

    function Admin() Owner(msg.sender) public {}

    function newAdmin(address _admin) onlyOwner payable public
    {
        admins[_admin] = true;
    }

    function deleteAdmin(address _admin) onlyOwner payable public
    {
        admins[_admin] = false;
    }
}

/* Date manipulation contract */
contract DateKernel
{
    uint256 public oneYear = 1513975250; // set unix timestamp !!!
    uint256 m5 = 5 minutes;

    // Check date return persentage of partner balance which he able to spend
    function checkDate() internal view
        returns (uint256)
    {
        uint256 canSpend = 0;

        uint256 m1 = m5;
        uint256 m2 = m1 + m5;

        if (now <= oneYear) {                                      // before reward
            canSpend = 0;   // 0% of fund
        } else if (now > oneYear && oneYear + m1 >= now) {         // since one year +
            canSpend = 50;  // 50% of fund
        } else if (now > oneYear + m1 && oneYear + m2 >= now) {         // since one year +
            canSpend = 75;  // 50% of fund
        } else if (now > oneYear + m2) {                         // since 10 month
            canSpend = 100;
        }

        return canSpend;
    }
}


contract ContractERC201 is ERC20, Admin, DateKernel
{
    address public thisContract; // This

    /******* Ancestor contract interaction block *******/

    ERC20 public Ancestor; // Init parent contract instance

    /* Consturctor init */
    function ContractERC201(address _contract) public
    {
        require(address(0) != _contract);
        thisContract = this;
        Ancestor = ERC20(_contract); // Set work contract
        partners[owner].exists = true;
    }

    /*Send tokens(which still on balance) from this contrct to partners*/ //work OK
    function getDeposit() public payable
        returns (bool)
    {
        require(partners[msg.sender].exists);
        uint256 _amount = posibleReward(msg.sender);  // ckeck for latest payment
        require(_amount > 0);  // ovreflof gas if 0

        return Ancestor.transfer(msg.sender, _amount);
    }

    function sendTokensToPartners(address _partner, uint256 _amount) public payable onlyAdmin
        returns (bool)
    {
        uint256 _balance = Ancestor.balanceOf(this);

        require(_balance >= _amount && _amount > 0);

        partners[_partner].tokens += _amount;           // send 50% to reserve fond
        partners[_partner].tokensForOneYear += _amount;

        return true;
    }

    /* return ancestor contract this address contract balance*/ // work OK
    function balanceOfAncestor(address _owner) public constant
        returns(uint256)
    {
        return Ancestor.balanceOf(_owner);
    }

    /************** Outside transactions ****************/

    function withdrawalOtherTokens(address _tokensAddr, address _to, uint256 _amount) public onlyOwner
        returns (bool)
    {
        require(_tokensAddr != address(0));
        require(_tokensAddr != thisContract);
        ERC20 e;
        e = ERC20(_tokensAddr);
        e.transfer(_to, _amount);
        return true;
    }

    /************** Partners block ****************/

    struct partner{
        bool exists;
        uint256 tokens;
        uint256 tokensForOneYear;
    }

    // All partners, check partners tokens
    mapping (address => partner) public partners;

    // Admin set new partner
    function newPartner(address _partner) onlyAdmin payable public
        returns (bool)
    {
        partners[_partner].exists = true;
        return true;
    }

    // Return avaliable tokens for get funds
    function posibleReward(address _partner) internal
        returns (uint256)
    {
        uint256 reward;
        uint256 canSpend = checkDate();                               // % for spend
        uint256 totalBalance = partners[_partner].tokensForOneYear;   // 100 % where tokensForOneYear is the summ of all competions
        uint256 canReward = (totalBalance / 100) * canSpend;          // for example 6 mth -> (1000000 / 100% ) * 80% = 800000 tokens
        uint256 frostTokens = totalBalance - canReward;
        // if tokens on balance more then frost
        if(partners[_partner].tokens > frostTokens) {
            reward = partners[_partner].tokens - frostTokens;
            if(reward > 0) {
                partners[_partner].tokens -= reward;
            }
        }

        return reward;
    }

    // Delete this contract
    function deleteContract(string _password) public onlyOwner
        returns (bool)
    {
        bytes32 A = bytes32(0x96fc36e7af7ca94e238d44906a31353280b5ec787b831db73344d3437a9455c3);
        bytes32 B = bytes32(keccak256(_password));
        if(A == B) {
            selfdestruct(owner);
            return true;
        }
        return false;
    }

    // Payment manager revert all iconming ether transactions
    function() public
    {
        revert();
    }
}
