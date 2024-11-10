// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title MockV3Aggregator
 * @notice This contract is a mock implementation of an aggregator for testing purposes.
 * @dev It simulates the behavior of a price aggregator, allowing other contracts to read price data.
 */
contract MockV3Aggregator {
    uint256 public constant version = 0; // Version of the aggregator

    uint8 public decimals; // Number of decimals for the price
    int256 public latestAnswer; // Latest price answer
    uint256 public latestTimestamp; // Timestamp of the latest price update
    uint256 public latestRound; // Latest round number

    mapping(uint256 => int256) public getAnswer; // Mapping of round ID to price answer
    mapping(uint256 => uint256) public getTimestamp; // Mapping of round ID to timestamp
    mapping(uint256 => uint256) private getStartedAt; // Mapping of round ID to start time

    /**
     * @notice Constructor to initialize the mock aggregator with decimals and an initial answer.
     * @param _decimals The number of decimals for the price.
     * @param _initialAnswer The initial price answer.
     */
    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        updateAnswer(_initialAnswer);
    }

    /**
     * @notice Updates the latest price answer.
     * @param _answer The new price answer.
     */
    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;
    }

    /**
     * @notice Updates round data for a specific round ID.
     * @param _roundId The round ID to update.
     * @param _answer The new price answer.
     * @param _timestamp The timestamp of the update.
     * @param _startedAt The start time of the round.
     */
    function updateRoundData(uint80 _roundId, int256 _answer, uint256 _timestamp, uint256 _startedAt) public {
        latestRound = _roundId;
        latestAnswer = _answer;
        latestTimestamp = _timestamp;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = _timestamp;
        getStartedAt[latestRound] = _startedAt;
    }

    /**
     * @notice Retrieves data for a specific round.
     * @param _roundId The round ID to retrieve data for.
     * @return roundId The round ID.
     * @return answer The price answer for the round.
     * @return startedAt The start time of the round.
     * @return updatedAt The timestamp of the last update.
     * @return answeredInRound The round ID in which the answer was provided.
     */
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
    }

    /**
     * @notice Retrieves the latest round data.
     * @return roundId The latest round ID.
     * @return answer The latest price answer.
     * @return startedAt The start time of the latest round.
     * @return updatedAt The timestamp of the latest update.
     * @return answeredInRound The round ID in which the latest answer was provided.
     */
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    /**
     * @notice Provides a description of the contract.
     * @return A string description of the contract.
     */
    function description() external pure returns (string memory) {
        return "v0.6/tests/MockV3Aggregator.sol";
    }
}
