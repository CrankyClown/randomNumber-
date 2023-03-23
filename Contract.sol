// Import the Chainlink library
import "github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/VRFConsumerBase.sol";

// Define the contract
contract RandomNumberGenerator is VRFConsumerBase {
    
    // Declare variables
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    uint256 public sampleSize;
    uint256 public uniqueNumbers;
    uint256[] public randomNumbers;
    
    // Constructor function
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        keyHash = _keyHash;
        fee = _fee;
        sampleSize = 10; // Set default sample size to 10
        uniqueNumbers = 5; // Set default number of unique numbers to 5
    }
    
    // Set sample size
    function setSampleSize(uint256 _sampleSize) external {
        sampleSize = _sampleSize;
    }
    
    // Set number of unique numbers
    function setUniqueNumbers(uint256 _uniqueNumbers) external {
        uniqueNumbers = _uniqueNumbers;
    }
    
    // Request random numbers
    function getRandomNumbers() public returns (uint256[] memory) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to fulfill request");
        require(sampleSize > 0, "Sample size must be greater than zero");
        require(uniqueNumbers > 0, "Number of unique numbers must be greater than zero");
        require(uniqueNumbers <= sampleSize, "Number of unique numbers must be less than or equal to sample size");
        
        uint256[] memory result = new uint256[](uniqueNumbers);
        for (uint256 i = 0; i < uniqueNumbers; i++) {
            bytes32 requestId = requestRandomness(keyHash, fee);
            emit RandomNumberRequested(requestId);
        }
        
        randomNumbers = result;
        return result;
    }
    
    // Callback function
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(randomNumbers.length < uniqueNumbers, "All random numbers have already been generated");
        
        bool isDuplicate = false;
        for (uint256 i = 0; i < randomNumbers.length; i++) {
            if (randomNumbers[i] == randomness) {
                isDuplicate = true;
                break;
            }
        }
        
        if (!isDuplicate) {
            randomResult = randomness;
            randomNumbers.push(randomness);
            emit RandomNumberGenerated(randomness);
        } else {
            bytes32 newRequestId = requestRandomness(keyHash, fee);
            emit RandomNumberRequested(newRequestId);
        }
    }
    
    // Events
    event RandomNumberRequested(bytes32 indexed requestId);
    event RandomNumberGenerated(uint256 indexed randomNumber);
}
