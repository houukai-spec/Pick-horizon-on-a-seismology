function edit_horizons_from_segy
% PSDM 多层位编辑器。运行后选择 SEG-Y，可多选已有 CMP/Depth_m TXT。
% 新建时选择保存目录和名字；列表切换当前层位，其他层位保留作参照。
% 已有与新建层位均可加点、上下左右拖动、左右续接和删除点。
% 左键加点/拖动；重拾区段后依次点左右端点，再补点；Ctrl+Z 撤销。
% Enter 保存当前层位，Esc 取消重拾；关闭窗口前提示未保存的修改。

%% 用户设置：所有可调参数集中在这里
sectionDirectory = "F:\修论\Data";
horizonDirectory = "F:\修论\Data";
depthSampleM = 2;
firstDepthM = 0;
maxDisplayTraces = 20000;
maxDisplaySamples = 10000;
clipPercentile = 99;
polarity = 1;
snapDepthToSample = true;
pickRadiusPixels = 10;
maxVisibleMarkers = 100;
horizontalMarginPercent = 2;
zoomButtonFactor = 1.5;
scrollZoomFactor = 1.25;
lineColors = lines(12);
textFormat = '%.17g\t%.17g\n';
%% =========================================================

[name,folder] = uigetfile({'*.sgy;*.segy','PSDM SEG-Y'}, ...
    '选择 PSDM section',char(sectionDirectory));
if isequal(name,0), return; end
inputSEGY = fullfile(folder,name);
meta = inspect_segy_cmp(inputSEGY);
[outputCmp,traceIndex] = unique(meta.cmp,'sorted');
traceStride = max(1,ceil(numel(traceIndex)/maxDisplayTraces));
choice = unique([1:traceStride:numel(traceIndex),numel(traceIndex)]);
sampleStride = max(1,ceil(meta.samplesPerTrace/maxDisplaySamples));
sampleIndex = unique([1:sampleStride:meta.samplesPerTrace,meta.samplesPerTrace]);
section = read_ibm_traces(inputSEGY,meta,traceIndex(choice),sampleIndex,polarity);
depthDisplay = firstDepthM+(sampleIndex-1)*depthSampleM;
clipValue = amplitude_percentile(section,clipPercentile);

fig = figure('Color','w','Name','PSDM 多 horizon 编辑器', ...
    'NumberTitle','off','Units','normalized','Position',[0.03 0.06 0.94 0.86]);
ax = axes('Parent',fig,'Position',[0.065 0.16 0.72 0.76]);
imagesc(ax,outputCmp(choice),depthDisplay,section);
set(ax,'YDir','reverse','Layer','top','TickDir','out');
colormap(ax,seismic_colormap(256));
clim(ax,[-clipValue clipValue]);
xlabel(ax,'CMP/CDP'); ylabel(ax,'Depth (m), TVD');
title(ax,name,'Interpreter','none');
ax.XAxis.Exponent = 0; ax.YAxis.Exponent = 0;
margin = (outputCmp(end)-outputCmp(1))*horizontalMarginPercent/100;
xlim(ax,[outputCmp(1)-margin outputCmp(end)+margin]);
hold(ax,'on');
originalXLim = xlim(ax); originalYLim = ylim(ax);
selected = plot(ax,NaN,NaN,'o','MarkerSize',9, ...
    'MarkerFaceColor',[0.2 1 0.2],'MarkerEdgeColor',[0 0.4 0],'HitTest','off');
items = struct('name',{},'path',{},'points',{},'history',{}, ...
    'dirty',{},'isNew',{},'line',{});
active = 0; dragIndex = 0; dragStart = []; selectedIndex = 0;
redrawStage = 0; redrawStart = [];
list = uicontrol(fig,'Style','listbox','Units','normalized', ...
    'Position',[0.82 0.43 0.16 0.48],'String',{},'Callback',@select_horizon);
status = uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[0.065 0.025 0.91 0.06],'BackgroundColor','w', ...
    'HorizontalAlignment','left','String','加载已有层位或新建层位。');
button('加载 horizon',[0.82 0.35 0.16 0.055],@load_horizons);
button('新建 horizon',[0.82 0.28 0.16 0.055],@new_horizon);
button('保存当前层位',[0.82 0.21 0.16 0.055],@save_current);
button('另存为',[0.82 0.14 0.16 0.055],@save_as);
button('撤销',[0.065 0.095 0.10 0.045],@undo);
button('重拾区段',[0.175 0.095 0.13 0.045],@start_redraw);
button('删除选中点',[0.315 0.095 0.13 0.045],@delete_point);
button('放大',[0.455 0.095 0.08 0.045],@(~,~)zoom_center(zoomButtonFactor));
button('缩小',[0.545 0.095 0.08 0.045],@(~,~)zoom_center(1/zoomButtonFactor));
button('全图',[0.635 0.095 0.08 0.045],@reset_view);
set(fig,'WindowButtonDownFcn',@mouse_down,'WindowButtonMotionFcn',@drag, ...
    'WindowButtonUpFcn',@release,'WindowKeyPressFcn',@key_press, ...
    'WindowScrollWheelFcn',@scroll_zoom,'CloseRequestFcn',@close_editor);
load_horizons([],[]);

    function button(label,position,callback)
        uicontrol(fig,'Style','pushbutton','String',label,'Units','normalized', ...
            'Position',position,'Callback',callback);
    end

    function load_horizons(~,~)
        release([],[]);
        [files,path] = uigetfile('*.txt','选择已有 horizon（取消可直接新建）', ...
            char(horizonDirectory),'MultiSelect','on');
        if isequal(files,0), return; end
        files = cellstr(string(files));
        for k = 1:numel(files)
            file = fullfile(path,files{k});
            data = readmatrix(file,'FileType','text','NumHeaderLines',1);
            data = sortrows(data(:,1:2),1);
            % 首尾 NaN 是拾取范围外的输出占位，不作为控制点；内部缺口保留。
            finite = find(isfinite(data(:,2)));
            points = data(finite(1):finite(end),:);
            [~,label] = fileparts(file);
            add_horizon(label,file,points,false);
        end
        horizonDirectory = string(path);
        refresh;
    end

    function new_horizon(~,~)
        release([],[]);
        path = uigetdir(char(horizonDirectory),'新 horizon 的保存目录');
        if isequal(path,0), return; end
        answer = inputdlg('Horizon 名字（无需 .txt）：','新建 horizon',1,{'New_Horizon_CMP_Depth'});
        if numel(answer)==0, return; end
        [~,label] = fileparts(answer{1});
        file = fullfile(path,[label '.txt']);
        if isfile(file)
            status.String = '该名字已有文件，请用另一个名字新建。';
            return
        end
        add_horizon(label,file,zeros(0,2),true);
        horizonDirectory = string(path);
        refresh;
    end

    function add_horizon(label,file,points,isNew)
        color = lineColors(mod(numel(items),size(lineColors,1))+1,:);
        h = plot(ax,NaN,NaN,'-','Color',color,'LineWidth',1.5,'HitTest','off');
        items(end+1) = struct('name',label,'path',file,'points',points, ...
            'history',{{}},'dirty',false,'isNew',isNew,'line',h);
        active = numel(items); selectedIndex = 0; redrawStage = 0;
    end

    function select_horizon(~,~)
        release([],[]);
        active = list.Value; selectedIndex = 0; redrawStage = 0;
        refresh;
    end

    function refresh
        labels = {items.name};
        for k = 1:numel(items)
            p = sortrows(items(k).points,1);
            set(items(k).line,'XData',p(:,1),'YData',p(:,2),'Marker','none','LineWidth',1.5);
            if items(k).dirty, labels{k} = [labels{k} ' *']; end
        end
        list.String = labels;
        set(selected,'XData',NaN,'YData',NaN);
        if active==0, return; end
        list.Value = active;
        p = sortrows(items(active).points,1);
        xl = xlim(ax); yl = ylim(ax);
        finite = find(isfinite(p(:,2)) & p(:,1)>=xl(1) & p(:,1)<=xl(2) ...
            & p(:,2)>=yl(1) & p(:,2)<=yl(2));
        markers = finite(1:max(1,ceil(numel(finite)/maxVisibleMarkers)):end);
        if numel(finite)>0, markers = unique([markers;finite(1);finite(end)]); end
        set(items(active).line,'LineWidth',2.5,'Marker','o', ...
            'MarkerSize',4,'MarkerIndices',markers);
        if selectedIndex>0
            xy = items(active).points(selectedIndex,:);
            set(selected,'XData',xy(1),'YData',xy(2));
        end
        status.String = sprintf('当前：%s | 单击加点/两端延长；按住点上下左右拖动；Delete 删除；Ctrl+Z 撤销；Enter 保存。',items(active).name);
    end

    function xy = mouse_position
        cp = ax.CurrentPoint; xy = cp(1,1:2);
        [~,nearest] = min(abs(outputCmp-xy(1)));
        xy(1) = outputCmp(nearest);
        xy(2) = max(depthDisplay(1),min(depthDisplay(end),xy(2)));
        if snapDepthToSample
            xy(2) = firstDepthM+round((xy(2)-firstDepthM)/depthSampleM)*depthSampleM;
        end
    end

    function remember
        items(active).history{end+1} = items(active).points;
        items(active).dirty = true;
    end

    function mouse_down(~,~)
        if active==0 || ~strcmp(fig.SelectionType,'normal'), return; end
        if ~isequal(ancestor(fig.CurrentObject,'axes'),ax), return; end
        xy = mouse_position;
        if redrawStage==1
            redrawStart = xy; redrawStage = 2;
            status.String = '再点重拾区段另一端（Esc 取消）。'; return
        elseif redrawStage==2
            if xy(1)==redrawStart(1), return; end
            remember;
            p = items(active).points;
            bounds = sort([xy(1),redrawStart(1)]);
            p(p(:,1)>=bounds(1) & p(:,1)<=bounds(2),:) = [];
            items(active).points = sortrows([p;redrawStart;xy],1);
            redrawStage = 0; selectedIndex = 0; refresh; return
        end
        p = items(active).points;
        box = getpixelposition(ax,true);
        cp = ax.CurrentPoint; raw = cp(1,1:2);
        offset = (p-raw).*[box(3)/diff(xlim(ax)) box(4)/diff(ylim(ax))];
        distances = sum(offset.^2,2); distances(~isfinite(distances)) = Inf;
        [distance,index] = min(distances);
        if numel(index)>0 && distance<=pickRadiusPixels^2
            selectedIndex = index; dragIndex = index; dragStart = p;
        else
            remember;
            p(p(:,1)==xy(1),:) = [];
            items(active).points = sortrows([p;xy],1);
            selectedIndex = find(items(active).points(:,1)==xy(1),1);
        end
        refresh;
    end

    function drag(~,~)
        if dragIndex==0, return; end
        xy = mouse_position;
        items(active).points(dragIndex,:) = xy;
        refresh;
    end

    function release(~,~)
        if dragIndex==0, return; end
        if ~isequaln(items(active).points,dragStart)
            items(active).history{end+1} = dragStart;
            items(active).dirty = true;
        end
        p = items(active).points;
        xy = p(dragIndex,:);
        p(dragIndex,:) = []; p(p(:,1)==xy(1),:) = [];
        items(active).points = sortrows([p;xy],1);
        selectedIndex = find(items(active).points(:,1)==xy(1),1);
        dragIndex = 0; refresh;
    end

    function undo(~,~)
        release([],[]);
        if active==0, return; end
        if numel(items(active).history)>0
            items(active).points = items(active).history{end};
            items(active).history(end) = []; items(active).dirty = true;
        end
        redrawStage = 0; selectedIndex = 0; refresh;
    end

    function delete_point(~,~)
        release([],[]);
        if active==0 || selectedIndex==0, return; end
        remember;
        items(active).points(selectedIndex,:) = [];
        selectedIndex = 0; refresh;
    end

    function start_redraw(~,~)
        release([],[]);
        if active==0, return; end
        redrawStage = 1;
        status.String = '点选重拾区段第一端，然后点另一端；旧区段替换后可继续补点。Esc 取消。';
    end

    function key_press(~,event)
        if strcmpi(event.Key,'z') && any(strcmpi(event.Modifier,'control'))
            undo([],[]);
        elseif strcmpi(event.Key,'backspace')
            undo([],[]);
        elseif strcmpi(event.Key,'delete')
            delete_point([],[]);
        elseif any(strcmpi(event.Key,{'return','enter'}))
            save_current([],[]);
        elseif strcmpi(event.Key,'escape')
            redrawStage = 0; refresh;
        end
    end

    function save_current(~,~)
        release([],[]);
        if active==0, return; end
        if items(active).isNew && ~isfile(items(active).path)
            write_current(items(active).path);
        else
            save_as([],[]);
        end
    end

    function save_as(~,~)
        release([],[]);
        if active==0, return; end
        [path,label] = fileparts(items(active).path);
        [file,path] = uiputfile('*.txt','另存 horizon（保留已有文件）', ...
            fullfile(path,[label '_edited.txt']));
        if isequal(file,0), return; end
        file = fullfile(path,file);
        if isfile(file)
            status.String = '为保留已有文件，请另存为其他名字。'; return
        end
        write_current(file);
    end

    function write_current(file)
        p = items(active).points;
        if sum(isfinite(p(:,2)))<2
            status.String = '请先拾取至少两个不同 CMP 的点。'; return
        end
        depth = interp1(p(:,1),p(:,2),outputCmp,'linear',NaN);
        % 已有层位不重新吸附整条线，保留未修改深度和 NaN 缺口。
        if items(active).isNew && snapDepthToSample
            depth = firstDepthM+round((depth-firstDepthM)/depthSampleM)*depthSampleM;
        end
        fid = fopen(file,'w'); cleanup = onCleanup(@()fclose(fid));
        fprintf(fid,'CMP\tDepth_m\n');
        fprintf(fid,textFormat,[outputCmp(:),depth(:)].');
        items(active).path = file; items(active).dirty = false;
        [~,items(active).name] = fileparts(file);
        refresh; status.String = ['已保存：' file];
    end

    function zoom_center(factor)
        zoom_about([mean(xlim(ax)),mean(ylim(ax))],factor);
    end

    function zoom_about(center,factor)
        xlim(ax,center(1)+(xlim(ax)-center(1))/factor);
        ylim(ax,center(2)+(ylim(ax)-center(2))/factor);
        refresh;
    end

    function scroll_zoom(~,event)
        if dragIndex~=0 || ~isequal(ancestor(hittest(fig),'axes'),ax), return; end
        cp = ax.CurrentPoint;
        zoom_about(cp(1,1:2),scrollZoomFactor^(-double(event.VerticalScrollCount)));
    end

    function reset_view(~,~)
        xlim(ax,originalXLim); ylim(ax,originalYLim);
        refresh;
    end

    function close_editor(~,~)
        release([],[]);
        if any([items.dirty])
            answer = questdlg('有未保存的修改，是否放弃并关闭？', ...
                '关闭编辑器','放弃并关闭','返回编辑','返回编辑');
            if ~strcmp(answer,'放弃并关闭'), return; end
        end
        delete(fig);
    end
end
function meta = inspect_segy_cmp(filename)
fid = fopen(filename,'r','ieee-be');
cleanup = onCleanup(@()fclose(fid));

fseek(fid,3200+16,'bof');
dtRaw = fread(fid,1,'uint16=>double');
fseek(fid,3200+20,'bof');
ns = fread(fid,1,'uint16=>double');
fseek(fid,3200+24,'bof');
formatCode = fread(fid,1,'uint16=>double');
fseek(fid,3200+304,'bof');
nExtendedTextHeaders = fread(fid,1,'int16=>double');

bytesPerSample = bytes_per_sample(formatCode);
traceDataStart = 3600 + 3200*nExtendedTextHeaders;

fseek(fid,0,'eof');
fileBytes = ftell(fid);
traceBytes = 240 + ns*bytesPerSample;
nTraceExact = (fileBytes-traceDataStart)/traceBytes;
nTrace = floor(nTraceExact);

cmp = zeros(nTrace,1);
progressStep = max(1,floor(nTrace/10));
for k = 1:nTrace
    traceStart = traceDataStart+(k-1)*traceBytes;
    fseek(fid,traceStart+20,'bof'); % SEG-Y trace header bytes 21--24: CDP ensemble number
    b = fread(fid,4,'uint8=>uint8');
    cmp(k) = be_i32(b);
    if mod(k,progressStep)==0 || k==nTrace
        fprintf('道头扫描：%3.0f%%\n',100*k/nTrace);
    end
end

meta = struct('samplesPerTrace',ns, 'formatCode',formatCode, ...
    'sampleIntervalHeaderRaw',dtRaw, 'bytesPerSample',bytesPerSample, ...
    'traceBytes',traceBytes, 'traceDataStart',traceDataStart, ...
    'traceCount',nTrace, 'cmp',cmp);
end

function data = read_ibm_traces(filename,meta,traceIndex,sampleIndex,polarity)
fid = fopen(filename,'r','ieee-be');
cleanup = onCleanup(@()fclose(fid));

data = zeros(numel(sampleIndex),numel(traceIndex),'single');
progressStep = max(1,floor(numel(traceIndex)/20));
for j = 1:numel(traceIndex)
    k = traceIndex(j);
    traceStart = meta.traceDataStart+(k-1)*meta.traceBytes;
    fseek(fid,traceStart+240,'bof');
    words = fread(fid,meta.samplesPerTrace,'uint32=>uint32');
    amp = ibm32_to_single(words);
    data(:,j) = single(polarity)*amp(sampleIndex);
    if mod(j,progressStep)==0 || j==numel(traceIndex)
        fprintf('振幅读取：%3.0f%%\n',100*j/numel(traceIndex));
    end
end
end

function n = bytes_per_sample(formatCode)
switch formatCode
    case {1,2,4,5,10}
        n = 4;
    case {3,11}
        n = 2;
    case {6,9,12}
        n = 8;
    case {7,15}
        n = 3;
    case {8,16}
        n = 1;
    otherwise
        error('不支持的 SEG-Y 数据格式码：%g。',formatCode);
end
end

function v = be_i32(b)
u = bitor(bitor(bitshift(uint32(b(1)),24),bitshift(uint32(b(2)),16)), ...
    bitor(bitshift(uint32(b(3)),8),uint32(b(4))));
v = double(typecast(u,'int32'));
end

function y = ibm32_to_single(w)
signValue = ones(size(w));
signValue(bitget(w,32)~=0) = -1;
exponent = double(bitand(bitshift(w,-24),uint32(127)))-64;
fraction = double(bitand(w,uint32(hex2dec('00FFFFFF'))))/2^24;
y = single(signValue.*fraction.*16.^exponent);
y(w==0) = 0;
end

function q = amplitude_percentile(a,p)
stride = max(1,floor(numel(a)/2e6));
v = abs(double(a(1:stride:end)));
v = sort(v(isfinite(v) & v>0));
if isempty(v)
    q = 1;
else
    index = max(1,min(numel(v),round(p/100*numel(v))));
    q = v(index);
end
end

function c = seismic_colormap(n)
anchorPosition = [0 0.18 0.36 0.50 0.64 0.78 0.90 1.00];
anchorColor = [ ...
    0.0000 0.0000 0.0000
    0.2500 0.2500 0.2500
    0.6902 0.6902 0.6902
    0.9412 0.9412 0.8784
    0.9412 0.9412 0.2510
    0.9412 0.6902 0.0000
    0.9412 0.1882 0.0000
    0.9412 0.0000 0.0000];
c = interp1(anchorPosition,anchorColor,linspace(0,1,n),'linear');
c = max(0,min(1,c));
end

