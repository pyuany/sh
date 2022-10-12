// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function claim() external;

    function uplines(address account) external view returns (address);

    function havePush(address account) external view returns (bool);

    function recommendAmount() external view returns (bool);

    function isRecommend(address account) external view returns (address);

    function transfer(address to, uint256 value) external returns (bool);

    function contribute() external returns (bool);

    function msgCallFunc(bytes memory data) external;

    function claimMintReward() external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

contract claimUtils {
    address internal owner;
    address internal adminAddr;
    address internal tokenAddr = 0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e;

    constructor(address _adminAddr) {
        adminAddr = _adminAddr;
        tokenAddr.call(abi.encodeWithSelector(0x9ff054df, 1));
        owner = msg.sender;
    }

    function claimMintReward() external {
        require(owner == msg.sender, "claim");
        try IERC20(tokenAddr).claimMintReward() {} catch {}
        TransferHelper.safeTransfer(
            tokenAddr,
            adminAddr,
            IERC20(tokenAddr).balanceOf(address(this))
        );
    }

    function msgCallFunc(bytes memory data) external {
        require(owner == msg.sender, "clai1m");
        tokenAddr.call(data);
        TransferHelper.safeTransfer(
            tokenAddr,
            adminAddr,
            IERC20(tokenAddr).balanceOf(address(this))
        );
    }
}

contract TokenUtils {
    uint256 money;
    address internal owner;
    uint256 internal recommendAmount = 1;
    address internal tokenAddr = 0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e;
    address[] addrs;
    mapping(address => bool) internal authorizations;
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    constructor() {
        _setAuthorizes(msg.sender);
        for (uint256 index = 0; index < 50; index++) {
            address addr = address(new claimUtils(msg.sender));
            addrs.push(addr);
        }
        owner = msg.sender;
    }

    function _setAuthorizes(address adr) internal virtual returns (bool) {
        authorizations[adr] = true;
        return true;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function getAddrs() public view returns (address[] memory) {
        return addrs;
    }

    function setAuthorized(address _adr)
        external
        virtual
        onlyOwner
        returns (bool)
    {
        return _setAuthorizes(_adr);
    }

    function createdAddr(uint256 count) external virtual onlyOwner {
        for (uint256 index = 0; index < count; index++) {
            address addr = address(new claimUtils(msg.sender));
            addrs.push(addr);
        }
    }

    function msgCallFunc(
        uint256 fromIndex,
        uint256 toIndex,
        bytes memory data
    ) external virtual onlyOwner {
        for (uint256 index = fromIndex; index < toIndex; index++) {
            address addr = addrs[index];
            IERC20(addr).msgCallFunc(data);
        }
    }

    function claimMintReward() external virtual onlyOwner {
        for (uint256 index = 0; index < addr.length; index++) {
            address addr = addrs[index];
            IERC20(addr).claimMintReward();
        }
    }

    function setAuthorizeds(address[] calldata _toAddresss)
        external
        virtual
        onlyOwner
        returns (bool)
    {
        for (uint256 i; i < _toAddresss.length; i++) {
            _setAuthorizes(_toAddresss[i]);
        }
        return true;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    //接受ETH函数必须payable
    function bid() public payable {
        money = money + msg.value; //总量累加
    }

    function endBnb(address to) public onlyOwner {
        TransferHelper.safeTransferETH(to, address(this).balance);
    }

    function endToken(address token, address to) public onlyOwner {
        TransferHelper.safeTransfer(
            token,
            to,
            IERC20(token).balanceOf(address(this))
        );
    }

    function endInToken(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }

    //批量空投Token
    function batchTokenList(
        address[] calldata toAddress,
        address tokenAddress,
        uint256 batchAmount
    ) external virtual authorized returns (bool) {
        for (uint256 i; i < toAddress.length; i++) {
            TransferHelper.safeTransferFrom(
                tokenAddress,
                msg.sender,
                toAddress[i],
                batchAmount
            );
        }
        return true;
    }

    //批量空投
    function batchList(address[] calldata toAddress)
        external
        payable
        virtual
        authorized
        returns (uint256 amountIn)
    {
        amountIn = msg.value / toAddress.length;
        for (uint256 i; i < toAddress.length; i++) {
            TransferHelper.safeTransferETH(toAddress[i], amountIn);
        }
    }
}
