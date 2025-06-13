// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StudentID
 * @dev NFT-based student identity card
 * Features:
 * - Auto-expiry after 4 years
 * - Renewable untuk active students
 * - Contains student metadata
 * - Non-transferable (soulbound)
 */
contract StudentID is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;

    struct StudentData {
        string nim;
        string name;
        string major;
        uint256 enrollmentYear;
        uint256 expiryDate;
        bool isActive;
        uint8 semester;
    }

    // TODO: Add mappings
    mapping(uint256 => StudentData) public studentData;
    mapping(string => uint256) public nimToTokenId; // Prevent duplicate NIM
    mapping(address => uint256) public addressToTokenId; // One ID per address

    // Events
    event StudentIDIssued(
        uint256 indexed tokenId,
        string nim,
        address student,
        uint256 expiryDate
    );
    event StudentIDRenewed(uint256 indexed tokenId, uint256 newExpiryDate);
    event StudentStatusUpdated(uint256 indexed tokenId, bool isActive);
    event ExpiredIDBurned(uint256 indexed tokenId);

    modifier isItemExist(uint256 tokenId) {
        require(ERC721._ownerOf(tokenId) != address(0), "Item doesn't exist!");
        _;
    }

    constructor() ERC721("Superman Is Dead", "SID") Ownable(msg.sender) {}

    /**
     * @dev Issue new student ID
     * Use case: New student enrollment
     */
    function issueStudentID(
        address _to,
        string calldata _nim,
        string calldata _name,
        string calldata _major,
        string calldata _uri
    ) public onlyOwner {
        // TODO: Implement ID issuance
        // Hints:
        // 1. Check NIM tidak duplicate (use nimToTokenId)
        // 2. Check address belum punya ID (use addressToTokenId)
        // 3. Calculate expiry (4 years from now)
        // 4. Mint NFT
        // 5. Set token URI (foto + metadata)
        // 6. Store student data
        // 7. Update mappings
        // 8. Emit event

        require(nimToTokenId[_nim] == 0, "NIM already registered");
        require(addressToTokenId[_to] == 0, "Address already registered");

        uint tokenId = ++_nextTokenId;

        ERC721._mint(_to, tokenId);
        ERC721URIStorage._setTokenURI(tokenId, _uri);

        uint _expiryDate = (4 * 365 days + block.timestamp) / 1 days;

        studentData[tokenId] = StudentData({
            nim: _nim,
            name: _name,
            major: _major,
            enrollmentYear: block.timestamp / 365 days,
            expiryDate: _expiryDate,
            isActive: true,
            semester: 1
        });

        nimToTokenId[_nim] = tokenId;
        addressToTokenId[_to] = tokenId;

        emit StudentIDIssued(tokenId, _nim, _to, _expiryDate);
    }

    /**
     * @dev Renew student ID untuk semester baru
     */
    function renewStudentID(
        uint256 tokenId
    ) public onlyOwner isItemExist(tokenId) {
        // TODO: Extend expiry date
        // Check token exists
        // Check student is active
        // Add 6 months to expiry
        // Update semester
        // Emit renewal event

        StudentData storage item = studentData[tokenId];
        require(item.isActive, "Student didn't active yet");

        item.expiryDate += 180 days;
        item.semester += 1;

        emit StudentIDRenewed(tokenId, item.expiryDate);
    }

    /**
     * @dev Update student status (active/inactive)
     * Use case: Cuti, DO, atau lulus
     */
    function updateStudentStatus(
        uint256 tokenId,
        bool isActive
    ) public onlyOwner isItemExist(tokenId) {
        // TODO: Update active status
        // If inactive, maybe reduce privileges
        studentData[tokenId].isActive = isActive;

        if (!isActive) {
            ERC721._burn(tokenId);
        }

        emit StudentStatusUpdated(tokenId, isActive);
    }

    /**
     * @dev Burn expired IDs
     * Use case: Cleanup expired cards
     */
    function burnExpired(uint256 tokenId) public {
        // TODO: Allow anyone to burn if expired
        // Check token exists
        // Check if expired (block.timestamp > expiryDate)
        // Burn token
        // Clean up mappings
        // Emit event

        require(isExpired(tokenId), "ID expired");

        require(
            ERC721.ownerOf(tokenId) == msg.sender ||
                Ownable.owner() == msg.sender,
            "Only token owner or contract owner"
        );

        address tokenOwner = ERC721.ownerOf(tokenId);

        delete nimToTokenId[studentData[tokenId].nim];
        delete addressToTokenId[tokenOwner];
        delete studentData[tokenId];

        ERC721._burn(tokenId);

        emit ExpiredIDBurned(tokenId);
    }

    /**
     * @dev Check if ID is expired
     */
    function isExpired(
        uint256 tokenId
    ) public view isItemExist(tokenId) returns (bool) {
        // TODO: Return true if expired
        return block.timestamp > studentData[tokenId].expiryDate;
    }

    /**
     * @dev Get student info by NIM
     */
    function getStudentByNIM(
        string calldata nim
    )
        public
        view
        returns (address owner, uint256 tokenId, StudentData memory data)
    {
        // TODO: Lookup student by NIM
        tokenId = nimToTokenId[nim];
        require(tokenId != 0, "NIM not found :(");

        owner = ERC721.ownerOf(tokenId);
        data = studentData[tokenId];

        return (owner, tokenId, data);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Removed                                  */
    /* -------------------------------------------------------------------------- */
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {}

    /**
     * ref: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/5146
     */

    /* -------------------------------------------------------------------------- */
    /*                               OpenZeppelin v5                              */
    /* -------------------------------------------------------------------------- */
    function _update(
        address from,
        uint256 tokenId,
        address to
    ) internal override(ERC721) returns (address) {
        // TODO: Make soulbound (non-transferable)
        // Only allow minting (from == address(0)) and burning (to == address(0))
        // require(from == address(0) || to == address(0), "SID is non-transferable");
        // super._beforeTokenTransfer(from, to, tokenId, batchSize);

        /* ---------------------------------- burn ---------------------------------- */
        /**
         * ref: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/4856#issuecomment-1910957242
         */
        if (to == address(0)) {
            delete studentData[tokenId];
            delete nimToTokenId[studentData[tokenId].nim];
            delete addressToTokenId[ownerOf(tokenId)];
        } else {
            require(from == address(0), "SID is non-transferable");
        }

        return ERC721._update(from, tokenId, to);
    }

    // Override functions required untuk multiple inheritance
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
