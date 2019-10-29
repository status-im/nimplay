import ../nimplay0_1


contract("NimCoin"):
  # Globals
  var
    name*: bytes32
    symbol*: bytes32
    decimals*: uint256
    total_supply*: uint256
    minter*: address
    initialised: bool

  # Maps
  balanceOf: StorageTable[address, uint256]
  allowances: StorageTable[address, address, uint256]

  initialised: bool

  # Events
  proc Transfer(ffrom: address, to: address, value: uint256) {.event.}
  proc Approval(owner: address, spender: address, value: uint256) {.event.}

  proc init*(nname: bytes32, ssymbol: bytes32, ddecimals: uint256, ttotal_supply: uint256) {.self,msg,log.} =
    if not self.initialised:
      return

    self.total_supply = ttotal_supply
    self.symbol = ssymbol
    self.decimals = ddecimals
    self.name = nname
    self.minter = msg.sender
    self.initialised = true
    log.Transfer(ZERO_ADDRESS, msg.sender, ttotal_supply)

  proc totalSupply*(): uint256 {.self.} =
    self.total_supply

  proc allowance(owner : address, spender : address): uint256 {.self.} =
    # @dev Function to check the amount of tokens that an owner allowed to a spender.
    # @param owner The address which owns the funds.
    # @param spender The address which will spend the funds.
    # @return An uint256 specifying the amount of tokens still available for the spender.
    self.allowances[owner][spender]

  proc transfer*(to: address, value: uint256): bool {.self,msg,log.} =
    # @param to The address to transfer to.
    # @param value The amount to be transferred.
    self.balanceOf[msg.sender] -= value
    self.balanceOf[to] += value
    log.Transfer(msg.sender, to, value)
    return true

  proc transferFrom(ffrom : address, to : address, value : uint256): bool {.self,msg,log.} =
    # @dev Transfer tokens ffrom one address to another.
    #     Note that while this function emits a Transfer event, this is not required as per the specification,
    #     and other compliant implementations may not emit the event.
    # @param ffrom address The address which you want to send tokens ffrom
    # @param to address The address which you want to transfer to
    # @param value uint256 the amount of tokens to be transferred
    self.balanceOf[ffrom] -= value
    self.balanceOf[to] += value
    self.allowances[ffrom][msg.sender] -= value
    log.Transfer(ffrom, to, value)
    return true

  proc approve(spender : address, value : uint256): bool {.self,msg,log.} =
    # @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    #      Beware that changing an allowance with this method brings the risk that someone may use both the old
    #      and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    #      race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    #      https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    # @param spender The address which will spend the funds.
    # @param value The amount of tokens to be spent.
    self.allowances[msg.sender][spender] =value 
    log.Approval(msg.sender, spender, value)
    return True

  proc mint(to: address, value: uint256) {.self,msg,log.} =
    # @dev Mint an amount of the token and assigns it to an account. 
    #      This encapsulates the modification of balances such that the
    #      proper events are emitted.
    # @param to The account that will receive the created tokens.
    # @param value The amount that will be created.

    assert msg.sender == self.minter
    assert to != ZERO_ADDRESS
    self.total_supply +=value 
    self.balanceOf[to] +=value 
    log.Transfer(ZERO_ADDRESS, to, value)
