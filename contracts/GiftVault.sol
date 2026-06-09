// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IOpenFourVault.sol";
import "./interfaces/IOpenFourModuleSchema.sol";
import "./interfaces/ITagDescriptor.sol";

/// @title GiftVault — X账号礼物金库
/// @notice 指定一个X(Twitter)账号作为礼物所有者，可随时将交易手续费定向到任意EVM地址
/// @dev 7天宽限期后未操作则丧失控制权，自动进入分红模式
contract GiftVault is IOpenFourVault, IOpenFourModuleSchema, ITagDescriptor {
    struct GiftConfig {
        string giftOwnerXHandle;  // 礼物所有者X账号
    }

    mapping(address => GiftConfig) internal _configs;
    mapping(address => address) internal _beneficiary;   // 当前受益地址
    mapping(address => uint256) internal _lastActivity;    // 最后操作时间
    mapping(address => uint256) internal _accumulated;     // 累积的BNB
    mapping(address => bool) internal _forfeited;          // 是否已丧失控制权
    address internal _fourCore;

    uint256 public constant GRACE_PERIOD = 7 days;

    modifier onlyCore() { require(msg.sender == _fourCore, "!core"); _; }
    error AlreadyInitialized();

    function init(address token, address fourCore, bytes calldata params, string calldata) external {
        if (address(_fourCore) != address(0)) revert AlreadyInitialized();
        _fourCore = fourCore;
        _configs[token] = abi.decode(params, (GiftConfig));
        _lastActivity[token] = block.timestamp;
    }

    function onBuy(address, uint256, uint256 payment, uint256, bytes calldata) external onlyCore {
        _accumulated[msg.sender] += payment;
    }

    function onSell(address, uint256, uint256 payment, uint256, bytes calldata) external onlyCore {
        _accumulated[msg.sender] += payment;
    }

    function vaultBalance() external view returns (uint256) {
        return _accumulated[msg.sender];
    }

    /// @notice 礼物所有者设置受益地址（通过X推文触发，此处为简化版直接设置）
    function setBeneficiary(address token, address beneficiary) external {
        if (_forfeited[token]) return;
        _beneficiary[token] = beneficiary;
        _lastActivity[token] = block.timestamp;
    }

    /// @notice 领取累积费用到受益地址
    function claim(address token, uint256 amount) external {
        require(!_forfeited[token], "forfeited");
        require(block.timestamp < _lastActivity[token] + GRACE_PERIOD || _lastActivity[token] == 0, "grace expired");
        require(amount <= _accumulated[token], "insufficient");
        _accumulated[token] -= amount;
        _lastActivity[token] = block.timestamp;
        payable(_beneficiary[token] != address(0) ? _beneficiary[token] : msg.sender).transfer(amount);
    }

    function checkForfeit(address token) external {
        if (!_forfeited[token] && block.timestamp >= _lastActivity[token] + GRACE_PERIOD) {
            _forfeited[token] = true;
        }
    }

    function getInitParams() external pure returns (bytes memory) {
        return abi.encode(GiftConfig({giftOwnerXHandle: ""}));
    }

    function moduleEncodeSchema() external pure returns (ModuleEncodeSchema memory) {
        ParamDescriptor[] memory params = new ParamDescriptor[](1);
        params[0] = ParamDescriptor("giftOwnerXHandle", "礼物所有者X账号", "X(Twitter)账号，可定向手续费到任意地址", "string", false, bytes32(0), bytes32(0), bytes32(0));
        return ModuleEncodeSchema(1, "module.vault.gift", params);
    }

    function descriptor() external pure returns (bytes8 tagId, string memory tag, string memory version) {
        tagId = bytes8(keccak256(bytes("module.vault.gift")));
        tag = "module.vault.gift";
        version = "v1.0.0";
    }
}
