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

    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
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
    uint256 public oneYear = 1540339200; // set unix timestamp 24.10.2018 0:0:00
    uint256 m28 = 28 * 1 days;
    uint256 m30 = 30 * 1 days;
    uint256 m31 = 31 * 1 days;

    // Check date return persentage of partner balance which he able to spend
    function checkDate() internal view
        returns (uint256)
    {
        uint256 canSpend = 0;

        uint256 m1 = m31;
        uint256 m2 = m1 + m30;
        uint256 m3 = m2 + m31;
        uint256 m4 = m3 + m31;
        uint256 m5 = m4 + m28;
        uint256 m6 = m5 + m31;
        uint256 m7 = m6 + m30;
        uint256 m8 = m7 + m31;
        uint256 m9 = m8 + m30;
        uint256 m10 = m9 + m31;

        if (now <= oneYear) {                                      // before reward
            canSpend = 0;   // 0% of fund
        } else if (now > oneYear && oneYear + m1 >= now) {         // since one year +
            canSpend = 50;  // 50% of fund
        } else if (now > oneYear + m1 && oneYear + m2 >= now) {    // since 1 month
            canSpend = 55;
        } else if (now > oneYear + m2 && oneYear + m3 >= now) {    // since 2 month
            canSpend = 60;
        } else if (now > oneYear + m3 && oneYear + m4 >= now) {    // since 3 month
            canSpend = 65;
        } else if (now > oneYear + m4 && oneYear + m5 >= now) {    // since 4 month
            canSpend = 70;
        } else if (now > oneYear + m5 && oneYear + m6 >= now) {    // since 5 month
            canSpend = 75;
        } else if (now > oneYear + m6 && oneYear + m7 >= now) {    // since 6 month
            canSpend = 80;
        } else if (now > oneYear + m7 && oneYear + m8 >= now) {    // since 7 month
            canSpend = 85;
        } else if (now > oneYear + m8 && oneYear + m9 >= now) {    // since 8 month
            canSpend = 90;
        } else if (now > oneYear + m9 && oneYear + m10 >= now) {   // since 9 month
            canSpend = 95;
        } else if (now > oneYear + m10) {                         // since 10 month
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
    function newPartner(address _partner) payable public onlyAdmin
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
