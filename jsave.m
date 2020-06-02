function jsave(filename, varargin)
%
% jsave
%   or
% jsave(fname)
% varlist=jsave(fname,'param1',value1,'param2',value2,...)
%
% Store variables in a workspace to a JSON or binary JSON file
%
% authors:Qianqian Fang (q.fang <at> neu.edu)
% created on 2020/05/31
%
% input:
%      fname: (optional) output file name; if not given, save to 'jamdata.jamm'
%           if fname has a '.json' or '.jdt' suffix, a text-based
%           JSON/JData file will be created (slow); if the suffix is '.jamm' or
%           '.jdb', a Binary JData (https://github.com/fangq/bjdata/) file will be created.
%      opt: (optional) a struct to store parsing options, opt can be replaced by 
%           a list of ('param',value) pairs - the param string is equivallent
%           to a field in opt. opt can have the following 
%           fields (first in [.|.] is the default)
%
%           ws ['base'|'wsname']: the name of the workspace in which the
%                         variables are to be saved
%           vars [{'var1','var2',...}]: list of variables to be saved
%
%           all options for saveubjson/savejson (depends on file suffix)
%           can be used to adjust the output
%
% output:
%      varlist: a list of variables loaded
%
% examples:
%      jsave  % save all variables in the 'base' workspace to jamdata.jamm
%      jsave('mydat.jamm','vars', {'v1','v2',...}) % save selected variables
%      jsave('mydat.jamm','compression','lzma')
%
% license:
%     BSD or GPL version 3, see LICENSE_{BSD,GPLv3}.txt files for details 
%
% -- this function is part of JSONLab toolbox (http://openjdata.org/jsonlab)
%

if(nargin==0)
    filename='jamdata.jamm';
end

opt=varargin2struct(varargin{:});

ws=jsonopt('ws','base',opt);

allvar=evalin(ws,'whos');
varlist=jsonopt('vars',{allvar.name},opt);

[isfound, dontsave]=ismember(varlist,{allvar.name});
if(any(isfound==0))
    error('specified variable is not found');
end

metadata=struct;
header=struct;
body=struct;

metadata=struct('CreateDate',datestr(now,29),...
                'CreateTime',datestr(now,'hh:mm:ss'),...
                'OriginalName',filename);

vers=ver('MATLAB');
if(isempty(vers))
    vers=ver('Octave');
    [verstr, releasedate]=version;
    vers.Release=verstr;
    vers.Date=releasedate;
end

metadata.CreatorApp=vers.Name;
metadata.CreatorVersion=vers.Version;
metadata.CreatorRelease=vers.Release;
metadata.ReleaseDate=vers.Date;
metadata.Parameters=opt;

header.(encodevarname('_DataInfo_'))=metadata;

for i=1:length(varlist)
    header.(varlist{i})=allvar(dontsave(i));
    body.(varlist{i})=evalin(ws,varlist{i});
end

savefun=@saveubjson;
if(regexp(filename,'\.[jJ][sS][oO][nN]$'))
    savefun=@savejson;
elseif(regexp(filename,'\.[jJ][dD][tT]$'))
    savefun=@savejson;
elseif(regexp(filename,'\.[mM][sS][gG][pP][kK]$'))
    savefun=@savemsgpack;
end

savefun('WorkspaceHeader',header,'filename',filename,varargin{:});
savefun('WorkspaceData',body,'filename',filename,'append',1,...
    'compression','zlib',varargin{:});
