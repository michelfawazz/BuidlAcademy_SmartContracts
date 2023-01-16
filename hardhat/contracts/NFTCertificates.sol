// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.7.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.7.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.7.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.7.0/utils/Strings.sol";
import "./Base64.sol";

interface IMetadata {

    function getCourse(uint256)
        external
        view
        returns (
            address,
            string memory,
            uint256,
            uint256
        );

    function isBuyerOfCourseFromCourse(uint256, address)
        external
        view
        returns (bool);
}

contract NFTCertificates is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IMetadata courseContract;

    //mapping to map tokens to courses
    mapping(uint256 => uint256) public tokenToCourse;
    //maping to make sure that users cannot mint twice for the same course
    mapping(uint256 => mapping(address => bool)) public courseToBuyer;

    //mapping tokenid to issue date
    mapping(uint256 => uint256) public tokenToIssueDate;

    //mapping tokenid to url
    mapping(uint256 => string) public tokenToUrl;

    //Attest event
    event Attest(address indexed to, uint256 indexed tokenId);
    event Revoke(address indexed to, uint256 indexed tokenId);

    // constructor() ERC721("BuidlNFTS", "BNFTS") {}
    //constructor with the name and symbol and the address of the course contract
    constructor(address _courseContract) ERC721("BUIDL Academy Certificates", "BAC") {
        courseContract = IMetadata(_courseContract);
    }



    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    

    //Public Mint
    function mint(uint256 courseId,string memory _url) public {
        require(
            courseContract.isBuyerOfCourseFromCourse(courseId, msg.sender),
            "You are not a buyer of this course"
        );
        //require that the user has not already minted for this course
        require(
            courseToBuyer[courseId][msg.sender] == false,
            "You have already minted for this course"
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        tokenToCourse[tokenId] = courseId;
        courseToBuyer[courseId][msg.sender] = true;
        tokenToIssueDate[tokenId] = block.number;
        
    

        tokenToUrl[tokenId] = _url;
    }


    //withdraw function to smart contract owner
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    //tokenURI function

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        //get the course id from the mapping
        uint256 courseId = tokenToCourse[tokenId];

        //get date of issue
        uint256 date = tokenToIssueDate[tokenId];

        string memory url = tokenToUrl[tokenId];
        

        (
            address owner,
            string memory courseName,
            uint256 courseDate,
            uint256 courseDuration
        ) = courseContract.getCourse(courseId);

         string[5] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500"  fill="#FFFFFF"><rect x="0" y="0" width="100%" height="100%" fill="#6173CE"/><text x="50%" y="30%" font-size="24" font-weight="bold" text-anchor="middle" dominant-baseline="central">BUIDL Academy Course Certificate</text><text x="50%" y="40%" font-size="20" font-weight="bold" text-anchor="middle" dominant-baseline="central">Course Name:</text><text x="50%" y="45%" font-size="18" text-anchor="middle" dominant-baseline="central">';
        parts[1] = courseName;


        // parts[2] = '</text><text x="200" y="230" font-size="20" font-weight="bold">Course ID:</text><text x="200" y="260" font-size="18">';
        // parts[3] = Strings.toString(courseId);


        parts[2] = '</text><text x="50%" y="55%" font-size="20" font-weight="bold" text-anchor="middle" dominant-baseline="central">Issue Block:</text><text x="50%" y="60%" font-size="18" text-anchor="middle" dominant-baseline="central">';

        parts[3] = Strings.toString(date);

        parts[4] = '</text></svg>';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
        );

        //name description image and attributes
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        courseName,
                        '", "description": "This is a certificate for the course ',
                        courseName,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", "attributes": [{"trait_type": "Course Name", "value": "',
                        courseName,
                        '"}, {"trait_type": "Certificate Issue Date", "value": "',
                        Strings.toString(date),
                        '"}, {"trait_type": "Course URL", "value": "',
                        url,
                        '"}]}'
                        
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }


    //override before and after token transfer functions tfor NFT to not be transferable unless from and to 0 address

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) pure override internal {
       
        require(from == address(0) || to == address(0), "NFT is not transferable");
    }

    //affter token if from is 0 address then emit attest event

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) override internal {
        
        if (from == address(0)) {
            emit Attest(to, tokenId);
        }
        if (to == address(0)) {
            emit Revoke(from, tokenId);
        }
    }


  function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only owner of the token can burn it");
        _burn(tokenId);
    }

    function revoke(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    
    

  
    

}
