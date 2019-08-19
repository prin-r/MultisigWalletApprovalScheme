pragma solidity 0.5.11;


contract MWAS {

    // Incrementing counter to prevent replay attacks
    uint256 public nonce;
    // The threshold
    uint256 public threshold;
    // The number of owners
    uint256 public expirationPeriod;
    // The number of owners
    uint256 public ownersCount;
    // List Guard
    address public constant GUARD = address(1);
    // proposal
    struct Proposal {
        mapping (address => address) approvals;
        uint256 proposeDate;
        uint256 nonce;
        uint256 value;
        address to;
        bytes data;
    }
    // Mapping to check if an address is an owner
    mapping (address => address) public owners;
    // proposals
    mapping (uint256 => Proposal) public proposals;

    // Events
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 indexed newThreshold);
    event ExpirationPeriodChanged(uint256 indexed newExpirationPeriod);
    event Executed(address indexed destination, uint256 indexed value, bytes data);
    event Received(uint256 indexed value, address indexed from);

    modifier onlyWallet() {
        require(msg.sender == address(this), "MSW: Calling account should be this wallet");
        _;
    }

    constructor(address[] memory _owners) public {
        require(_owners.length > 0, "MSW: Number of initial owners should > 0");
        expirationPeriod = 3 days;
        owners[GUARD] = GUARD;
        for(uint256 i = 0; i < _owners.length; i++) {
            addOwner(_owners[i])
            ownersCount++;
        }
        // threshold = 50%
        setThreshold(500000000000000000);
        emit ExpirationPeriodChanged(expirationPeriod);
    }

    function () external payable {
        emit Received(msg.value, msg.sender);
    }

    function isOwner(address someone) public view returns(bool) {
        return owners[someone] != address(0);
    }

    function execute(uint256 proposalID) public {
        require(isOwner(msg.sender));
        Proposal storage p = proposals[proposalID];
        require(p.proposeDate > 0 && now - p.proposeDate < expirationPeriod);



        if(approvalsCount * 1e18 >= threshold * ownersCount ) {
            (bool success,) = _to.call.value(_value)(_data);
            require(success, "MSW: External call failed");
            emit Executed(_to, _value, _data);
            return;
        }
        // If we reach that point then the transaction is not executed
        revert("MSW: Not enough valid signatures");
    }

    function changeThreshold(uint256 _newThreshold) public onlyWallet {
        require(_newThreshold >= 1e17 && _newThreshold <= 1e18, "MSW: Invalid new threshold");
        threshold = _newThreshold;
        emit ThresholdChanged(_newThreshold);
    }

    function addOwner(address _owner) public onlyWallet {
        require(isOwner(_owner) == false, "MSW: Already owner");
        owners[_owner] = owners[GUARD];
        owners[GUARD] = _owner;
        ownersCount++;
        emit OwnerAdded(_owner);
    }

    function removeOwner(address _owner, address _prevOwner) public onlyWallet {
        require(ownersCount > 0, "MSW: Should have at least 1 owner");
        require(isOwner(_owner) == true, "MSW: Not an owner");
        require(owners[_prevOwner] == _owner);
        owners[_prevOwner] = owners[_owner];
        owners[_owner] = address(0)
        ownersCount--;
        emit OwnerRemoved(_owner);
    }

    function getAllOwners() public view returns(address[] memory) {
        address[] memory _owners = new address[](ownersCount);
        address currAddr = owners[GUARD];
        uint256 i = 0;
        while () {
            _owners[i] = currAddr;
            currAddr = owners[currAddr];
            i++;
        }
        return _owners;
    }


}