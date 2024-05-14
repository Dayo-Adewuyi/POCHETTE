// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@account-abstraction/contracts/core/EntryPoint.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "../interfaces/IERC20.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Account is IAccount {

    event ReceiveTransfer(address indexed from, uint256 amount);
    string public username;
    AggregatorV3Interface internal dataFeed;

    constructor(string memory _username) {
        username = _username;
        dataFeed = AggregatorV3Interface(
            0x59F1ec1f10bD7eD9B938431086bC1D9e233ECf41
        );
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 /* userOpHash */,
        uint256
    ) external pure returns (uint256 validationData) {
        // Recover the address that signed the user operation
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encode(userOp))),
            userOp.signature
        );

            // Additional validation checks can be added here if needed
            return 0; // Valid operation
       
    }

    function ercTransfer(address _token, address _to, uint _value) external {
        require(_token != address(0), "invalid token address");
        require(_to != address(0), "invalid beneficiary address");  
        require(_value > 0, "invalid amount");
        require(IERC20(_token).transferFrom(msg.sender, _to, _value), "transfer failed");
    }

    function getEthPrice() external view returns (int) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    receive() external payable {
        emit ReceiveTransfer(msg.sender, msg.value);
    }

    function sendEther(address payable _to, uint256 _amount) external {
        require(_to != address(0), "invalid recipient address");
        require(_amount > 0 && _amount <= address(this).balance, "invalid amount");
    
        (bool success, ) = _to.call{value: _amount}(""); // Check for success of ether transfer
        require(success, "ether transfer failed");
    }
}

contract AccountFactory {
    mapping(string => address) public usernameToAccount;

    function createAccount(
        string calldata _username
    ) external returns (address) {
        require(usernameToAccount[_username] == address(0), "Username already exists");
        
        bytes32 salt = keccak256(abi.encode(_username));
        bytes memory creationCode = type(Account).creationCode;
        bytes memory bytecode = abi.encodePacked(
            creationCode,
            abi.encode(_username)
        );

        address addr = Create2.computeAddress(salt, keccak256(bytecode));
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return addr;
        }

        return deploy(salt, bytecode, _username);
    }

    function deploy(
        bytes32 salt,
        bytes memory bytecode,
        string memory _username
    ) internal returns (address addr) {
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");

        usernameToAccount[_username] = addr;
    }
}
