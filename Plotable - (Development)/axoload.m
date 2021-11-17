%function [data,samp_freq,time,name,comment,n_sweep,numtag,...
%	  nchan,chan_rec,ch_sampseq,tagblock,pretrigtime,...
%	  rec_date,rec_time,dt,filename]=axoload(filename,readall,showinfo)
%
%   Reads old (ver < 2.0), new (ver 2.0) axotape dat files and 
%   Axoscope ABF files, and converts file information into MATLAB
%   variables.  Requires Matlab v 4.0 or greater.
%   Adapted from AXOREAD.M by S. DeSerres
%   Input Parameters
%	filename = filename given as a character vector.  eg. for
%		for file TEST.DAT, use axoload('TEST.DAT');
%		If not given, axoload will query user for
%		a filename.
%	readall = flag.  !0=read entire file. 0=query time to read
%   Output Parameters (description of first 5 parameters)
%	data = data in column vectors by channels (mV)
%	samp_freq = sample rate/channel.  If the sample sweep has 2
%		sample rates, a 2x2 matrix is returned containing 
%		sample rates in the 1st column and breakpoints in the
%		2nd column. (Hz)
%	time = time vector for one sweep. (ms)
%	name = channel name
%	comment = user comment attached to abf file.		
%    Written: Ken Yoshida, 7 Aug 1998

function [data,samp_freq,time,name,comment,n_sweep,numtag,...
	  nchan,chan_rec,ch_sampseq,tagblock,pretrigtime,...
	  rec_date,rec_time,dt,filename]=axoload(filename,readall,showinfo)

if nargin < 3
	showinfo=1;
	if nargin < 2
		readall=0;
		if nargin < 1
			[filename,path]=uigetfile('*.dat;*.abf','Open Axon File');
			filename=sprintf('%s%s',path,filename);
		end
	end
end

fid=fopen(filename,'r','l');	% Assumes little-endian *.abf or *.dat file
if fid==-1     % File not opened
	fprintf(1,'File Opening Error, %s',filename);
	data=[];
	return;
end

%%%%% Read Axotape Binary File (ABF) header information %%%%%%%%%%%%%%%%%%%%%%

%%%%% Group #1 File ID & Actual Content Information %%%%%%%%%%%%%%%%%%%%%%%%%%
%if fseek(fid,0,'bof') == -1 data=[];time=1; return;end;
ver_chk=fread(fid,4,'char');
%version=round(10*fread(fid,1,'float'))/10, pause;

if ver_chk'=='ABF ' %%%%% For ABF format (axotape v2.0 or axoscope)
	version=2.0;
else
	if fseek(fid,0,'bof') == -1 data=[];time=1; return;end;
	ver_chk=fread(fid,1,'float')
	if ver_chk==10 %%%%% For Axotape v1.x FETCHEX 5.2 data file format
		version=1.0;
	else
		fclose(fid);
		fprintf(1,'Unknown File Type');
		data=[];
		return;
	end
end
		
if version == 2.0	
	fseek(fid,8,'bof');
	opmode=fread(fid,1,'int16');
	n_samp=fread(fid,1,'int32');
	if fseek(fid,16,'bof') == -1 data=[];time=3; return;end;     %%%%% fseek to 16
	n_sweep=fread(fid,1,'int32');
	if fseek(fid,24,'bof') == -1 data=[];time=3; return;end;     %%%%% fseek to 24
	rec_time=fread(fid,1,'int32'); 	% in sec


%%%%% Group #2 File Structure Information %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if fseek(fid,40,'bof') == -1 data=[];time=3; return;end;    %%%%% fseek to 40
	datablock=fread(fid,1,'int32');
	tagblock=fread(fid,1,'int32');
	numtag=fread(fid,1,'int32');

%this section is imported directly from axoread.m  Needs to be looked at later.
	if tagblock~=0
		tagjump=tagblock*512;
		for i=1:numtag
			status=fseek(fid,tagjump+(i-1)*64,'bof');
			tag_pos(i)=fread(fid,1,'int32');
		end
		tag_pos=tag_pos*stime/1000000;
	else
		clear numtag tagblock;
	end

%%%%% Group #3 Trial Hierarchy Information %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if fseek(fid,120,'bof') == -1 data=[];time=4; return;end;   %%%%% fseek to 120
	nchan=fread(fid,1,'int16');
	stime=fread(fid,1,'float');   % in uSec
	stime2=fread(fid,1,'float');	% 2nd Sample interval in uSec
	if fseek(fid,194,'bof') == -1 data=[];time=4.1; return;end;   %%%%% fseek to 194
	n_clkchange=fread(fid,1,'int32');
	
	if fseek(fid,138,'bof') == -1 data=[];time=4.2; return;end;  %%%%% fseek to 138
	n_sweepsamp=fread(fid,1,'int32');
	pretrig=fread(fid,1,'int32');

	etime=n_samp*stime/1000000;   % Total elapsed time in file

%%%%% Group #5 Hardware Information %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if fseek(fid,244,'bof') == -1 data=[];time=5; return;end;   %%%%% fseek to 244
	ADrange=fread(fid,1,'float'); % + voltage range in V (half total range)
	if fseek(fid,4,'cof') == -1 data=[];time=6; return;end;     %%%%% fseek to 252
	ADres=fread(fid,1,'int32');    % ADC count corresponding to +voltage range

	AD2mV=ADrange/ADres*1000;     % Data in mV

%%%%% Group #6 Environmental Information %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if fseek(fid,310,'bof') == -1 data=[];time=8; return;end;   %%%%% fseek to 310
	comment=fread(fid,[1,56],'char');
	comment=setstr(comment);

%%%%% Group #7 Multi-channel Information %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if fseek(fid,410,'bof') == -1 data=[];time=9; return;end;   %%%%% fseek to 410
	ch_sampseq=fread(fid,[1,16],'int16');
	for i=1:nchan
		chan_rec(i)=ch_sampseq(i)+1;
	end
	%%%%% Read Channel Name
	for i=1:16
		 for j=1:10
			 name(i,j)=fread(fid,1,'char');
		 end
		 %fprintf(1,'%s\n',name(i,:));
	end
	name=setstr(name);
	name=name(chan_rec,:);
	%%%%% Read Channel ADC Unit
	for i=1:16
		for j=1:8
			ADCUnit(i,j)=fread(fid,1,'char');
		end
	end

	if fseek(fid,922,'bof') == -1 data=[];time=9; return;end;   %%%%% fseek to 922
	InstScaleFactor=fread(fid,[1,16],'float');
	InstOffset=fread(fid,[1,16],'float');

end
if version==1.0
	opmode=3;
	stime2=0;
	pretrig=0;
	n_sweep=1;
	status=fseek(fid,4,'bof');
	nchan=fread(fid,1,'float');
	status=fseek(fid,16,'bof');
	stime=fread(fid,1,'float');
	status=fseek(fid,28,'bof');
	etime=fread(fid,1,'float');
	status=fseek(fid,36,'bof');
	rec_date=fread(fid,1,'float');
	status=fseek(fid,24,'bof');
	rec_time=fread(fid,1,'float');
	status=fseek(fid,(53-1)*4,'bof');
	ADrange=fread(fid,1,'float');
	status=fseek(fid,(55-1)*4,'bof');
	ADres=2^(fread(fid,1,'float')-1);
	status=fseek(fid,320,'bof');
	comment=fread(fid,[1,77],'char');
	comment=setstr(comment);
	status=fseek(fid,480,'bof');
	chan_rec=[1:nchan]-1;

	for i=1:16
		 for j=1:10
			 name(i,j)=fread(fid,1,'char');
		 end
	end
	name=setstr(name);
	status=fseek(fid,88,'bof');
	tagblock=fread(fid,1,'float');
	if tagblock~=0
		 tagjump=tagblock*512;
		 status=fseek(fid,tagjump,'bof');
		 numtag=fread(fid,1,'int16');
		 tag_pos=fread(fid,[1,numtag],'int');
		 tag_pos=tag_pos/stime;
	else
		 numtag=0;
	end

	AD2mV=ADrange/ADres*1000;     % Data in mV

	if fseek(fid,410,'bof') == -1 data=[];time=9; return;end;   %%%%% fseek to 410
	ch_sampseq=fread(fid,[1,16],'int16');
end

%%%%%%  Evaluation of time variables  %%%%%%
samp_freq=1000000/(nchan*stime);
if stime2 ~= 0
	samp_freq=[samp_freq,1;1000000/(nchan*stime2),n_clkchange];
end
lmax=etime*1000000/(stime*nchan);
pretrigtime=pretrig*stime/1000;
minutes=fix(rec_time/60);
seconds=rem(rec_time,60);
hours=fix(minutes/60);
minutes=rem(minutes,60);
minu_str=int2str(minutes);
if size(minu_str)==1
	 real_min(1,1)=int2str(0);
	 real_min(1,2)=minu_str;
	 minu_str=real_min;
end
sec_str=int2str(seconds);
if size(sec_str)==1
	 real_sec(1,1)=int2str(0);
	 real_sec(1,2)=sec_str;
	 sec_str=real_sec;
end

%%%%%%  Screen display of file characteristics  %%%%%%
foutid=1; % Print to screen
if showinfo==1
	if version==2
		fprintf(foutid,'Filename: %s\n',filename);
		fprintf(foutid,'Comment: %s\n',comment);
		fprintf(foutid,'Samp Rate(Hz): %7.2f\t#Sweeps: %d\n',samp_freq,n_sweep);
		fprintf(foutid,'Col\tCh#\tUnits            \tCh.Name\n');
		for i=1:nchan
			fprintf('%3d\t%3d\t(1/1000)x%s\t%s\n',i,chan_rec(i),setstr(ADCUnit(i,:)),name(i,:));
		end
	end
elseif showinfo==2
	str_date=int2str(rec_date);
	year=str_date(1,1:2);
	month=str_date(1,3:4);
	day=str_date(1,5:6);


	fprintf(foutid,'\nFilename: %s',filename);
	fprintf(foutid,'\nRecording date: %s/%s/%s ',year,month,day);
	fprintf(foutid,'            Recording time: %g:%s:%s ',hours,minu_str,sec_str);
	fprintf(foutid,'\nNumber of channels: %g',nchan);
	fprintf(foutid,'                Sampling frequency (Hz): %g',samp_freq(1,1));
	if exist('numtag')==1
		fprintf(foutid,'\nNumber of tags: %g',numtag);
	elseif opmode==2  | opmode==4
		fprintf(foutid,'\nNumber of sweeps averaged: %g',num_sweeps);
		fprintf(foutid,'        Raw sweeps saved: ');
		if(n_actualsweep==1)
			fprintf(foutid,'No');
		else
			fprintf(foutid,'Yes');
		end
	else
		fprintf(foutid,'\n');
	end
	fprintf(foutid,'\nComment: %s',comment);
	fprintf(foutid,'\n\n    DATA COLUMN ');
	fprintf(foutid,'                SIGNAL NAME');
	if version==2.0  % New ABF Format
		cnt=1;
		for i=chan_rec(1):chan_rec(nchan)
			fprintf(foutid,'\n        %g',cnt);
			fprintf(foutid,'                       %s',name(i,:));
			cnt=cnt+1;
		end
	else
		for i=1:nchan
			fprintf(foutid,'\n        %g',i);  
			fprintf(foutid,'                       %s',name(16-i+1,:));
		end
	end

	if opmode==2 | opmode==4
		fprintf(foutid,'\n\nTotal elapsed time:  %g s',etime);
	else
		fprintf(foutid,'\n\nTotal elapsed time:  %g s',fix(etime));
	end
	fprintf(foutid,'\n');
	if exist('numtag')==1
		for i=1:numtag
			fprintf(foutid,'\nPosition of tag #%g: %g s',i,round(tag_pos(i)));
		end
		fprintf(foutid,'\n');
	else
		fprintf(foutid,'\n\n');
	end
end

%%%%%%  Start and end of data to read  %%%%%%
if opmode==3
	if readall==0
		fprintf(1,'Sweeplength = %f sec ',etime);
	    start=input('Starting point in sec: ');
		if isempty(start)
			start=0;
			lstart=0;
			lend=lmax;
		else
		    final=input('Ending point in sec: ');
		    lend=final*1000000/(stime*nchan);
		    if lend>lmax
		           lend=lmax;
		    end
		end
	    lstart=start*1000000/(stime*nchan);
	    if lstart>lmax
	           lstart=lmax-2000;
	    end
	    if lstart>lend
	           lstart=lend-2000;
		end
	else
		start=0;
		lstart=0;
		lend=etime*1000000/(stime*nchan);
	end
else
	start=0;
	lstart=0;
	lend=etime*1000000/(stime*nchan);
%    fprintf('\n\nHit a key to continue...'),pause
%    fprintf('\n');
end

%if version==0
%	n_rows=lend-lstart;
%else
%	n_rows=n_samp/nchan;
%end

n_rows=lend-lstart;

%%%%%%  Reading the data  %%%%%%
if version == 2.0
	status=fseek(fid,datablock*512+(lstart*nchan*2),'bof');
else
	status=fseek(fid,1024+(lstart*nchan*2),'bof');
end

data=fread(fid,[nchan,n_rows],'int16');
data=data';
if version==2.0
	data=data*AD2mV/1000;	% in V
	for i=1:nchan
		data(:,i)=data(:,i)/InstScaleFactor(chan_rec(i))+InstOffset(chan_rec(i));
	end
	data=data*1000;		% in mV
else
	A=data;
	for i=1:nchan
		data(:,i)=A(:,nchan-i+1)*AD2mV;
	end
end

if size(samp_freq,1) == 1
	dt=1000/samp_freq(1,1);
	if opmode == 1 | opmode== 3
		time=start:dt:n_rows*dt+start-dt;  % Time in mSec
	else	
		time=[1:n_sweepsamp]*dt;
	end
else
	dt=1000./samp_freq(:,1);
	time=[0:(samp_freq(2,2)-1)]*dt(1);
	time2=[1:length((samp_freq(2,2)+1):n_sweepsamp)]*dt(2);
	time=[time,time2+((samp_freq(2,2)-1)*dt(1))];
end

fclose(fid);


return;




clear
axoload

