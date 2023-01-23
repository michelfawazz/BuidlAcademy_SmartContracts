// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//create a smart contract to keep track of courses created by the user

interface Token {
    //balanceOf(address account) returns (uint256)
    function balanceOf(address account) external view returns (uint256);
}

contract Buidl is Context, Ownable {
    //create a struct to keep track of the courses
    struct Course {
        address owner;
        string name;
        uint256 id;
        uint256 price;
        uint256 courseCount;
        uint256 amountGeneratedStable;
        uint256 amountGeneratedMatic;
        mapping(address => bool) Buyers;
    }

    struct TokenInfo {
        IERC20 paytoken;
    }

    TokenInfo[] public AllowedCrypto;

    //create a mapping to keep track of the courses
    mapping(uint256 => Course) public courses;

    //map courses to the owner
    mapping(address => uint256[]) public ownerToCourses;

    //buyers will be able to buy courses map the buyers to the courses they own
    mapping(address => uint256[]) public buyerToCourses;

    //whitelist course creators
    mapping(address => bool) public whiteListCourseCreators;

    //create a counter to keep track of the courses
    uint256 public courseCounter;

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */

    //constructor
    constructor() {
        courseCounter = 0;
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/
            ,
            ,

        ) = /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return price;
    }

    function addCurrency(IERC20 _paytoken) public onlyOwner {
        AllowedCrypto.push(TokenInfo({paytoken: _paytoken}));
    }

    //COURSE CREATOR FUNCTIONS //

    //create a function to create a course
    function createCourse(
        string memory _name,
        uint256 _price
    ) public {
        require(
            whiteListCourseCreators[_msgSender()] == true,
            "You are not whitelisted to create courses"
        );

        uint256 _courseId = courseCounter;
        //require that the course at the id does not exist
        require(courses[_courseId].id == 0, "Course already exists");

        
        
        courses[_courseId].owner = _msgSender();
        courses[_courseId].name = _name;
        courses[_courseId].id = _courseId;
        courses[_courseId].price = _price;
        courses[_courseId].courseCount = 0;
        courses[_courseId].amountGeneratedStable = 0;
        courses[_courseId].amountGeneratedMatic = 0;

        //add the course to the owner
        ownerToCourses[_msgSender()].push(_courseId);
        courseCounter++;
    }

    //create a function to transfer the ownership of the course
    function transferCourse(uint256 _id, address _newOwner) public {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //remove mapping of old owner in ownertocourses
        address prevowner =courses[_id].owner;

        //in ownerTcourse remove _id from prev ownwer
        for(uint i=0; i<ownerToCourses[prevowner].length; i++){
            if(ownerToCourses[prevowner][i] == _id){
                delete ownerToCourses[prevowner][i];
            }
        }

       
        //transfer the ownership of the course
        courses[_id].owner = _newOwner;

        //add the course to the new owner
        ownerToCourses[_newOwner].push(_id);
       
    }

    //delete a course
    function deleteCourse(uint256 _id) public {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //delete the course
        delete courses[_id];

        //delete the course from the owner
        uint256[] storage coursesOfOwner = ownerToCourses[_msgSender()];
        for (uint256 i = 0; i < coursesOfOwner.length; i++) {
            if (coursesOfOwner[i] == _id) {
                coursesOfOwner[i] = coursesOfOwner[coursesOfOwner.length - 1];
                coursesOfOwner.pop();
                break;
            }
        }
    }

    //change the price of a course
    function changeCoursePrice(uint256 _id, uint256 _newPrice) public {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //change the price of the course
        courses[_id].price = _newPrice;
    }

    //add a buyer to the course
    function addBuyer(uint256 _id, address _buyer) public onlyOwner {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //add the buyer to the course
        courses[_id].Buyers[_buyer] = true;

        //add the course to the buyer
        buyerToCourses[_buyer].push(_id);
    }

    //remove a buyer from the course
    function removeBuyer(uint256 _id, address _buyer) public onlyOwner {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //remove the buyer from the course
        courses[_id].Buyers[_buyer] = false;

        //remove the course from the buyer
        uint256[] storage coursesOfBuyer = buyerToCourses[_buyer];
        for (uint256 i = 0; i < coursesOfBuyer.length; i++) {
            if (coursesOfBuyer[i] == _id) {
                coursesOfBuyer[i] = coursesOfBuyer[coursesOfBuyer.length - 1];
                coursesOfBuyer.pop();
                break;
            }
        }
    }

    //BUYER FUNCTIONS //

    //create a function to buy a course
    function buyCourse(uint256 _id, uint256 _pid) public payable {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner != _msgSender(),
            "You are the owner of the course"
        );

        // //check if the course price is equal to the msg.value
        // require(
        //     courses[_id].price == msg.value,
        //     "The price of the course is not equal to the msg.value"
        // );

        //check if balance is greater than or equal to the price
        //if pid is 0 or 1 then execute this
        if (_pid == 0 || _pid == 1) {
            TokenInfo storage tokens = AllowedCrypto[_pid];

            IERC20 paytoken;
            paytoken = tokens.paytoken;
            require(
                paytoken.balanceOf(_msgSender()) >= courses[_id].price,
                "You do not have enough balance to buy the course"
            );

            // //90% of the price goes to the course creator and 10% goes to the buidl platform
            uint256 creatorShare = (courses[_id].price * 90) / 100;
            // //push the amount generated to the course
            courses[_id].amountGeneratedStable += creatorShare;
            // //transfer the price to the contract owner

            //transfer courses[_id].price to the contract
            paytoken.transferFrom(
                _msgSender(),
                address(this),
                courses[_id].price
            );

            //transfer 90% of the price to the course creator
            paytoken.transfer(courses[_id].owner, creatorShare);
            //add the course to the buyer
            buyerToCourses[_msgSender()].push(_id);
            //add the buyer address to the buyers
            courses[_id].Buyers[_msgSender()] = true;
            //increment the course count
            courses[_id].courseCount += 1;
            

        }

        //if pid is 2 then execute this
        if (_pid == 2) {
            //get the price of the course using getcourseprice function
            uint256 coursePrice = getCoursePriceInETH(_id);

            //check if msg value is greater than or equal to the course price
            require(
                msg.value >= coursePrice,
                "You do not have enough balance to buy the course"
            );

            // //90% of the price goes to the course creator and 10% goes to the buidl platform
            uint256 creatorShare = (coursePrice * 90) / 100;
            // //push the amount generated to the course
            courses[_id].amountGeneratedMatic += creatorShare;

            // //transfer 90% of the price to the course creator
            payable(courses[_id].owner).transfer(creatorShare);

            //add the course to the buyer
            buyerToCourses[_msgSender()].push(_id);
            //add the buyer address to the buyers array
            courses[_id].Buyers[_msgSender()] = true;
            //increment the course count
            courses[_id].courseCount += 1;
            
        }
    }

    //calculate the price of the course in eth
    function getCoursePriceInETH(uint256 _id)
        public
        view
        returns (uint256 price)
    {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //get the price of ETH in USD
        int256 ethPriceInUSD = getLatestPrice();
        // ethPriceInUSD has 8 decimals

        //get the price pf the course
        uint256 coursePriceInWEIusd = courses[_id].price;
        //coursePriceInWEIusd has 18 decimals

        //convert ethprice in usd to have 18 decimals
        uint256 ethPriceInUSD18 = uint256(ethPriceInUSD) * 10**10;

        //calculate the price of the course in ETH
        uint256 coursePriceInETH = (coursePriceInWEIusd * 10**18) /
            ethPriceInUSD18;

        return coursePriceInETH;
    }

    //GETTER FUNCTIONS //

    //create a function to get the course details
    function getCourse(uint256 _id)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256
        )
    {
        return (
            courses[_id].owner,
            courses[_id].name,
            courses[_id].price,
            courses[_id].id
        );
    }

    //create a function to get the courses of the buyer
    function getBuyerCourses() public view returns (uint256[] memory) {
        return buyerToCourses[_msgSender()];
    }

    //create a function to get the courses of the owner
    function getOwnerCourses() public view returns (uint256[] memory) {
        return ownerToCourses[_msgSender()];
    }

    // //get all buyers of a course
    // function getBuyersOfCourse(uint256 _id)
    //     public
    //     view
    //     returns (address[] memory)
    // {
    //     //check if the course exists
    //     require(courses[_id].id != 0, "Course does not exist");

    //     //check if the course belongs to the owner
    //     require(
    //         courses[_id].owner == _msgSender(),
    //         "You are not the owner of the course"
    //     );

    //     address[] memory buyers = new address[](courses[_id].Buyers.length);
    //     uint256 counter = 0;
    //     for (uint256 i = 0; i < courses[_id].Buyers.length; i++) {
    //         if (courses[_id].Buyers[i]) {
    //             buyers[counter] = i;
    //             counter++;
    //         }
    //     }
    //     return buyers;
    // }

    // //get number of buyers of a course
    // function getNumberOfBuyersOfCourse(uint256 _id)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return courses[_id].Buyers.length;
    // }

    //check if the user is a buyer of a course
    function isBuyerOfCourseFromCourse(uint256 _id, address _buyer)
        public
        view
        returns (bool)
    {
        return courses[_id].Buyers[_buyer];
    }

    //check if the user has bought a specific course
    function isBuyerOfCourse(uint256 _id) public view returns (bool) {
        return courses[_id].Buyers[_msgSender()];
    }

    //WHITELIST FUNCTIONS //

    //create a function to whitelist course creators
    function whitelistCreator(address _courseCreator) public onlyOwner {
        whiteListCourseCreators[_courseCreator] = true;
    }

    //create a function to remove course creators from the whitelist
    function removeCreatorFromWhitelist(address _courseCreator)
        public
        onlyOwner
    {
        whiteListCourseCreators[_courseCreator] = false;
    }

    //create a function to check if the course creator is whitelisted
    function isCreatorWhitelisted(address _courseCreator)
        public
        view
        returns (bool)
    {
        return whiteListCourseCreators[_courseCreator];
    }

    //get current course count
    function getCourseCount() public view returns (uint256) {
        return courseCounter;
    }

    //ONLY OWNER FUNCTIONS//

    //create a function to withdraw the funds
    function withdraw(uint256 _pid) public onlyOwner {
        if (_pid == 0 || _pid == 1) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
        }
        if (_pid == 2) {
            payable(owner()).transfer(address(this).balance);
        }
    }
}
