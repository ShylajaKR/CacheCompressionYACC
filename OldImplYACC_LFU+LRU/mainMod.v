`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:13:34 09/12/2018 
// Design Name: 
// Module Name:    mainMod 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//LRU+LFU
//////////////////////////////////////////////////////////////////////////////////
module mainMod(clock,address);

input clock;
input [31:0]address;
//tag-21 bits, index-3 bits, block id-2 bits, offset-6 bits
parameter dataSize=511; //64 bytes. Each byte is 8 bits each 64*8=512 bits
parameter way=7;
parameter set=7;
parameter SBtagsize=26;
//Superblock: tag-5 bits [26:6], comp_factor-2 bits[5:4], block_id-4 bits[3:0]

reg [SBtagsize:0]tagArray[set:0][way:0];
reg [dataSize:0]dataArray[set:0][way:0];
reg [2:0]lruShiftReg[set:0][way:0];
integer counter[set:0][way:0];

reg foundDatainCache;
reg [dataSize:0]data; //Data 

reg [1:0] CF;

integer file_outputs; // var to see if file exists 
integer scan_outputs; // captured text handler

integer cache_Hit=0,cache_Miss=0;
integer count=0,enter=0;

initial
begin
	//open the data Memory file
	file_outputs = $fopen("C:/readFile.txt", "r"); //Opening text file
   if (file_outputs == 0) begin             // If outputs file is not found
      $display("data_file handle was NULL"); 
      $finish;
   end
end

always @(posedge clock && (count<=26)) //Only when there is a change in the 
begin
	enter=enter+1;
	$display($time,"  Address:%h",address);
	findDataInCache(address,foundDatainCache,data);//task

	if(foundDatainCache)
	begin
		//No need to go to memory and update cache or use LRU policy
		//decompress the data and display 
		//decompress();
		cache_Hit=cache_Hit+1;
		$display($time ,"  Cache HIT and data read=%h and Most_Recent=%b Number_Of_Cache_Hit=%d\n",data,lruShiftReg,cache_Hit);		
	end

	else 
	begin
		findDataInMemory(address,data);//task
		//compress();
		findCompFactor(data,CF);
		updateCache(address,data,CF); //YACC logic

		//send uncompressed data to lower level cache
		cache_Miss=cache_Miss+1;
		$display($time ,"  Cache MISS and data read=%h & Number_Of_Cache_Miss=%d\n",data,cache_Miss);
	end	
	count=count+1;
end

//Task to find the data in cache
task findDataInCache;
input [31:0] address;
output foundDatainCache;
output[dataSize:0]data;
integer index;

reg[20:0]tag; //21 tag bits
reg[1:0]blockId;
reg[1:0]CF;
reg matchFlag;

integer i;
begin
	index = address[10:8]; //integer index
	blockId = address[7:6];
	tag = address[31:11];
	$display($time,"  tag=%b index=%d blockId=%b ",tag,index,blockId);
	i=0;
	matchFlag = 0;
	foundDatainCache=0;
	while(i<=way && !matchFlag) //Four and 2 blocks will have the same tag in case of CF=00 and CF=01 
	begin
		if(tag == tagArray[index][i][26:6])//If there is a match of tag
		begin
			if(tagArray[index][i][5:4] == 2'b00)begin
				if(blockId == tagArray[index][i][3:2])
					matchFlag = 1;
			end
			if(tagArray[index][i][5:4] == 2'b01)begin
				if( (blockId == tagArray[index][i][3:2]) || (blockId == tagArray[index][i][1:0]) )
					matchFlag = 1;
			end
			if(tagArray[index][i][5:4] == 2'b10)begin
				if( ((blockId==2'b00)&&(tagArray[index][i][0]==1'b1))||((blockId==2'b01)&&(tagArray[index][i][1]==1'b1))||((blockId==2'b10)&&(tagArray[index][i][2]==1'b1))||((blockId==2'b11)&&(tagArray[index][i][3]==1'b1)) )
					matchFlag = 1;	
			end
		end
	i=i+1;
	end
	i=i-1;
	
	if(matchFlag == 1) begin
		CF = tagArray[index][i][5:4];
		
		case(CF)
		2'b00: //No compression
			data=dataArray[index][i];

		2'b01: //Compression /2
		begin
			if(blockId == tagArray[index][i][1:0])
			data=dataArray[index][i][255:0];
			if(blockId == tagArray[index][i][3:2])
			data=dataArray[index][i][511:256];
		end

		2'b10: //Compression /4
		begin
			if(blockId == 2'b00)
			data=dataArray[index][i][127:0];
			else if(blockId == 2'b01)
			data=dataArray[index][i][255:128];
			else if(blockId == 2'b10)
			data=dataArray[index][i][383:256];
			else
			data=dataArray[index][i][511:384];
		end
	
		2'b11:
			data=512'bx;
		endcase
	
		foundDatainCache = 1;
		//Update LRU shift register..
		/*i is the way where the data has been found
		  find i in shift reg and shift data till until i is not found.. It is for sure will be there
		  lruSR[index][0 to i]*/		
		updateCounter(index,i);
		updateLruShiftRegister(index,i);
		
		$display($time,"Counter=%d",counter[index][i]);
		
	end// only if there is a match of address in cache 
end
endtask

task findDataInMemory;
input [31:0] address;
output [dataSize:0]data;
integer offset,quotient,quotient1,newLineNum;
begin
	offset = address; //decimal eqnt of address
	quotient = offset/64;	
	
	if(quotient<=1630814)begin
		$fseek(file_outputs,((128*quotient)+(quotient*2)),0);	
		$display($time,"  Line number:%d",quotient);
	end	
	else begin
		quotient1 = quotient/64;
		newLineNum = quotient-(64*quotient1);
		$fseek(file_outputs,((128*newLineNum)+(newLineNum*2)),0);
		$display($time,"  Line number:%d",newLineNum);		
	end
	
	scan_outputs = $fscanf(file_outputs, "%h\n", data);     //Outputs line text
	
   //$fclose(file_outputs); //Closing files just in case to prevent wasting memory
	$display($time,"  File operation: Data =%h",data);
end
endtask

task findCompFactor;
input [dataSize:0]data;
output[1:0]CF;
begin
	if(data == 512'b0)
		CF=2'b10;
	else if(data[dataSize:128] == 384'b0) //CF is 4
		CF=2'b10;
	else if(data[dataSize:256] == 256'b0) //CF is 2
		CF=2'b01;	
	else CF=2'b00; //No compression	
	$display($time, "  Comp factor:%b",CF);
end
endtask

task updateCache; //YACC algorithm
input [31:0]address;
input [dataSize:0]data;
input [1:0] CF;

integer index,i;

reg[dataSize:0]updatedData; //final concatenated data
reg[1:0]blockId;
reg[20:0]tag;

reg [SBtagsize:0]SBtag;

reg isEmpty,isMatch,isUpdated; //flags

begin
/* First find the index where the data has to be stored..
Based on the CF check the matching block or an empty block
If yes, then add and update the tag array and counter array corresponding to CF
If none of the block is free, then find the LRU block and delete that whole block and update with a new
block. 
*/	
	i=0;
	isEmpty=1'b0; isMatch=1'b0; isUpdated=1'b0;
	index = address[10:8];
	blockId = address[7:6];
	tag = address[31:11];
	
	if(CF == 2'b00)begin
	// No point in finding the matching block because whole block has to be replaced.
		findEmptyBlock(index,i,isEmpty);
		
		if(!(isEmpty))begin
			lruPolicy(index,i); //index is input.. i is output
		end
			
		SBtag = {tag,CF,blockId,2'b00};
		updateDataTagArray(data,SBtag,index,i,1'b0);
	end
	
	else begin
	/*In case of /2 and /4 CF we have to find the blocks which are existing and which are half empty
	  If Yes, then just update the required part
	  If No, then find an empty block and then update the same
	  If no empty block then use LRU policy 
	  
	  In each case updating data and tag array is different */	   
		findMatchingTags(tag,CF,index,i,isMatch);
		if(!isMatch)begin
			findEmptyBlock(index,i,isEmpty);
			
			if(!(isEmpty))begin
				lruPolicy(index,i);
			end
			//No match found..  Update block as new block			
			if(CF == 2'b01)begin
				updatedData = {256'bx,data[255:0]};
				SBtag = {tag,CF,2'bxx,blockId};
			end
			else begin
				//bit is 1 in that position to indicate data exist
				case(blockId)
					2'b00:begin
						updatedData = {384'bx,data[127:0]};
						SBtag = {tag,CF,3'b0,1'b1}; 
					end
					2'b01:begin
						updatedData = {256'bx,data[127:0],128'bx};
						SBtag = {tag,CF,2'b0,1'b1,1'b0}; 
					end
					2'b10:begin
						updatedData = {128'bx,data[127:0],256'bx};
						SBtag = {tag,CF,1'b0,1'b1,2'b0}; 
					end
					2'b11:begin
						updatedData = {data[127:0],384'bx};
						SBtag = {tag,CF,1'b1,3'b0}; 
					end					
				endcase
			end			
		end
		
		else begin
		//Match found...Update only required part
			if(CF == 2'b01)begin
				updatedData = {data[255:0],dataArray[index][i][255:0]};
				SBtag = {tagArray[index][i][26:4],blockId,tagArray[index][i][1:0]};
			end
			
			else begin
			/* for CF=10 3 possible vacant spaces can exist and the data has to be stored in corresponding
			  locations since blockId for CF=10 is not stored... */
				if( (tagArray[index][i][0] == 1'b0) && (blockId == 2'b00) )begin
					updatedData = {dataArray[index][i][511:128],data[127:0]};
					SBtag = {tagArray[index][i][26:1],1'b1};
				end
				
				if( (tagArray[index][i][1] == 1'b0) && (blockId == 2'b01) )begin
					updatedData = {dataArray[index][i][511:256],data[127:0],dataArray[index][i][127:0]};
					SBtag = {tagArray[index][i][26:2],1'b1,tagArray[index][i][0]};
				end
				
				if( (tagArray[index][i][2] == 1'b0) && (blockId == 2'b10) )begin
					updatedData = {dataArray[index][i][511:384],data[127:0],dataArray[index][i][255:0]};
					SBtag = {tagArray[index][i][26:3],1'b1,tagArray[index][i][1:0]};
				end
				
				if( (tagArray[index][i][3] == 1'b0) && (blockId == 2'b11) )begin
					updatedData = {data[127:0],dataArray[index][i][383:0]};
					SBtag = {tagArray[index][i][26:4],1'b1,tagArray[index][i][2:0]};
				end
			end
			isUpdated=1'b1;
		end		
		updateDataTagArray(updatedData,SBtag,index,i,isUpdated);
	end	
	updateCounter(index,i);
	$display($time,"Counter=%d",counter[index][i]);
end
endtask

task findEmptyBlock;
input integer index;
output integer i;
output isEmpty;
begin
	i=0;isEmpty=1'b0;
	while(i<=way && !isEmpty)begin
		if(dataArray[index][i] === 512'bx)
			isEmpty=1; //flag has been used in order to break from the loop...
		i=i+1;
	end
	i=i-1;
	$display($time, "  Empty block: Index=%d",i);
end 
endtask

task lruPolicy;
input integer index;
output integer i;
integer pos,value,j;
reg isSame,found;
begin	
	j=0; isSame=1'b0; pos=0; found=1'b0;
	//Find the lowest count LFU
	value = counter[index][0];
	for(i=1;i<=way;i=i+1)begin	
		if(value > counter[index][i])begin
			value = counter[index][i];			
			pos = i;
		end		
	end
	i = pos; 
	//Find the repetition of the lowest count
	while( (j<=way)&&(!isSame) )begin
		if( (counter[index][i] == counter[index][j])&&(i!=j) )
			isSame=1'b1;
		j=j+1;
	end
	//If repetition find the least recently used LRU
	j=way;
	if(isSame == 1'b1)begin
		while( (j!=0)&&(!found) )begin
			value=lruShiftReg[index][j];
			if(counter[index][i] == counter[index][value])
				found=1'b1;
			j=j-1;
		end
		i=lruShiftReg[index][j+1];
	end
	//To reset the counter because the data is getting replaced..
	counter[index][i]=0;
	$display($time, "  LRU index=%d",i);
end 	
endtask

task findMatchingTags;
input [20:0]tag;
input [1:0]CF;
input integer index;
output integer i;
output isMatch;
begin
	i=0;isMatch=1'b0;
	while((i<=way) && (!isMatch))begin
		if( (tag == tagArray[index][i][26:6])&&(CF == tagArray[index][i][5:4]) )begin		
			if(CF == 2'b01)begin
				if(dataArray[index][i][511:256] === 256'bx)
					isMatch=1;
			end
			else begin
				if( (dataArray[index][i][127:0]===128'bx)||(dataArray[index][i][255:128]===128'bx)||(dataArray[index][i][383:256]===128'bx)||(dataArray[index][i][511:384]===128'bx) )
					isMatch=1;
			end
		end
		i=i+1;
	end
	i=i-1;
	$display($time, "  Entered matching tags Index=%d",i);
end 
endtask

task updateDataTagArray;
input[dataSize:0]updatedData;
input[SBtagsize:0]SBtag;
input integer index,i;
input isUpdated;
integer j;
begin
		j=way;
		dataArray[index][i]=updatedData;
		tagArray[index][i]=SBtag;
		//update LRU shift register
		//If data is update or replace then index is already present in LRUregister
		if( (isUpdated == 1'b1)||(counter[index][i]==0) )
			updateLruShiftRegister(index,i);
		else begin
			while(j!=0)
			begin
				lruShiftReg[index][j]=lruShiftReg[index][j-1];
				j=j-1;
			end
			lruShiftReg[index][j]=i;	
		end
		$display($time , "  Data=%h  SBtag=%b  Most_Recent=%b",dataArray[index][i],tagArray[index][i],lruShiftReg);
end
endtask

//Shift the positions to right by one bit and insert the recently used way index.
task updateLruShiftRegister;
input integer index,i;
integer j;
begin
	j=0;
	if(lruShiftReg[index][0]!=i)begin
		while(lruShiftReg[index][j]!=i)
			j=j+1;
		while(j!=0)begin
			lruShiftReg[index][j]=lruShiftReg[index][j-1];
			j=j-1;
		end
		lruShiftReg[index][0]=i;			
	end
end
endtask

//Increment the counter whenever there is a cache read or write
task updateCounter;
input integer index,i;
begin
	if(counter[index][i] === 32'bx)
		counter[index][i]=0;
	counter[index][i]=counter[index][i]+1;
end
endtask

endmodule
