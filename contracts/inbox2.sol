//Setup of a private blockchain with
//minimum 2 parties (Automobile manufacturer and
//OEM manufacturer). The Blockchain solution is
//enabled to track the movement of automobile spare parts from
//OEM warehouse to Automobile manufacturer.


pragma solidity ^0.4.17;

contract Inbox{

  function Inbox() public payable{

  }

  event ItemAddedbyOEM(address oemaddress,bytes32 itemname,uint quantityofitem);
  event PartsRequestbyManufacturer(bytes32 nameofpart,uint numberofparts);
  event morePartsRequestbyManufacturer(bytes32 nameofthepart,uint numberoftheparts);
  event OEMPaid(address _oemsaddress,uint moneyinthepoolforoem);
  event DefectReturn(bytes32 defectiveitem,uint numberofdefective);
  event DealerReady(uint thevehicleid);

  struct auto_industry {

    uint typ;
    address add;

  }

  // add oem to the network
  mapping(address => auto_industry ) addautoindustry;

  function add_OEM() {

    addautoindustry[msg.sender]=auto_industry(1,msg.sender);

  }

  modifier only_OEM() {

    if (addautoindustry[msg.sender].typ==1){
      _;
    }

    else {
      throw;
    }

  }
  // add automobile manufacturer
  function add_AUTO_MANU() {

    addautoindustry[msg.sender]=auto_industry(2,msg.sender);

  }

  modifier only_AUTO_MANU() {

    if (addautoindustry[msg.sender].typ==2){
      _;
    }

    else {
      throw;
    }

  }

  mapping (bytes32 => uint) parts_mapping;
  mapping (bytes32 => uint) id_mapping;
  mapping (bytes32 => uint) time_mapping;
  mapping (bytes32 => bytes32) hashing_item;
  mapping (bytes32 => uint) price_mapping;

  //adding the part to list
  function additem(bytes32 name, uint quantity, uint ids,uint price) only_OEM {

    uint p=parts_mapping[name];
    parts_mapping[name]=p+quantity;
    uint time_now=now;
    id_mapping[name] = ids;
    time_mapping[name]=time_now;
    price_mapping[name]=price;
    hashing_item[name]=sha3(name,ids,time_now);
    ItemAddedbyOEM(msg.sender,name,quantity);

  }

  //displays the no of quantity remaining for a particular part
  function display(bytes32 part_name) constant returns(uint) {

    return parts_mapping[part_name];

  }


  function display_time(bytes32 part_name) constant returns(uint) {

    return time_mapping[part_name];

  }

  //modiier takes name and id of the part and tells weather it is genuine
  modifier auth_part(bytes32 name, uint id_item) {

    uint  time_created=time_mapping[name];
    bytes32 hash_temp=sha3(name,id_item,time_created);
    bytes32 orig_hash=hashing_item[name];
    if(hash_temp==orig_hash) {
      _;
    }
    else {
      throw;
    }

  }

  uint pooltime;

  // used to calculate money for desired part from oem
  function buy_item_amount (bytes32 name_of_part , uint how_many) constant returns(uint) {

    uint amount = how_many * price_mapping[name_of_part];
    return amount;

  }

  // checking for authenticity of parts and paying temporarily to the pool
  function use_OEM_Parts(bytes32 name_of_part, uint how_many, uint id_of_item) auth_part(name_of_part , id_of_item) payable {

    if( parts_mapping[name_of_part] < how_many ){
      morePartsRequestbyManufacturer(name_of_part,how_many);
    }

    parts_mapping[name_of_part] = parts_mapping[name_of_part] - how_many;
    uint amount = msg.value;
    this.transfer(amount);
    pooltime=now;

    PartsRequestbyManufacturer(name_of_part,how_many);


  }


  function getPoolMoney() constant returns (uint){

    return this.balance;

  }

  //for giving back defective items,after this manufacturer gets his money and oem takes the defective part
  function defect(bytes32 _name_of_part, uint no_of_pieces) only_AUTO_MANU {

    uint __amount = no_of_pieces * price_mapping[_name_of_part];
    msg.sender.transfer(__amount);
    DefectReturn(_name_of_part,no_of_pieces);

  }

  //by this function oem can take out money out of the pool to his account
  function payOEM() payable only_OEM() {

    if(now-pooltime > 36000){
      OEMPaid(msg.sender, this.balance);
      msg.sender.transfer(this.balance);
    }

  }
 mapping (uint => vehicle) partinauto;
 struct vehicle
 {
   uint vehicle_id;
   string vehicle_name;
 }
 mapping (uint => uint) completeness;
//for assigning the part to the vehicle
 function item_to_vehicle(uint partid,string vehicle_n,uint _vehicle_id) only_AUTO_MANU
 {
   if(completeness[_vehicle_id]==1)
   {
     throw;
   }
   else
   {
   partinauto[partid]=vehicle(_vehicle_id,vehicle_n);
   }
 }
//for finding the location where the part is
 function item_location (uint partid) constant returns(uint a,string b)
 {
   a=partinauto[partid].vehicle_id;
   b=partinauto[partid].vehicle_name;
 }

 function v_assembled(uint vehicle_id_)
 {
   completeness[vehicle_id_]=1;
   DealerReady(vehicle_id_);
 }
  function () payable{

  }

}
