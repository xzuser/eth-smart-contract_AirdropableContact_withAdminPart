contract Test {
    /* just for tests NEED delete !!! */
    function sellManually(uint256 msgval) public payable
    {
        require(msg.value >= 1 ether / 10);              // requere transaction value more then 0.1 eth

        uint256 _msgval = msgval * DEC;

        require(_msgval < price);

        uint256 amount = _msgval / price;

        assert(partners[msg.sender].exists);             // only if is partner

        uint256 _balance = Ancestor.balanceOf(this);

        require(_balance >= amount && amount > 0);

        uint256 _amount = amount / 2;

        Ancestor.transfer(msg.sender, _amount);           // send 50% to the partners wallet

        partners[msg.sender].tokens += _amount;           // send 50% to reserve fond
        partners[msg.sender].tokensForOneYear += _amount;
    }
}
