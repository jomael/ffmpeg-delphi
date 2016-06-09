unit avprobe;
{$I VCL.inc}
interface
uses Classes,SysUtils, avformat,avcodec, avutil, rational, Graphics,
swscale, PixFmt, Frame;

type
  TAVProbe=class(TPersistent)
  private
    FRealWidth, FRealHeight:Integer;

    FFileName: string;
    FActive: Boolean;
    fmt_ctx:PAVFormatContext;
//    iformat:PAVInputFormat;
    FHasAudio: Boolean;
    FHasVideo: Boolean;
    FAudioEncoderName: string;
    FVideoEncoderName: string;
    FVideoWidth: integer;
    FVideoHeight: integer;
    FSampleRate: integer;
    FChannels: Integer;
    FBytePerSample:Integer;
    FAudioBitrate: integer;
    FVideoBitrate: Integer;
    FVideoFrameRate: Double;
    FBitmap: TBitmap;
    FDuration: Double;
    FStartTime:Int64;
    //thumbnail
    FThumbnailWidth: Integer;
    FThumbnailHeight: Integer;
    FVideoStream:integer;
    FCodecCtx: PAVCodecContext;
    FCodec: PAVCodec;
    FFrame, FFrameRGB: PAVFrame;
    buf_to_free: Pointer;
    FSwsCtx: PSwsContext;
    FHSub,FVSub:Integer;
    FEndTime: Int64;
    FTimeStamp: Int64;
    FInputFormat: string;
    FEof: Boolean;

    avcodec_opts: array [AVMediaType] of PAVCodecContext;
    FFormat: string;
    procedure SetActive(const Value: Boolean);
    procedure SetFileName(const Value: string);
    procedure CheckCodecOfStream(stream: PAVStream);
    procedure SetThumbnailHeight(const Value: Integer);
    procedure SetThumbnailWidth(const Value: Integer);
    procedure CloseFile;
    procedure SetTimeStamp(const Value: Int64);
    procedure SetInputFormat(const Value: string);
    function GetChapterCount: Integer;
    function GetChapterEnd(Index: Integer): Int64;
    function GetChapterStart(Index: Integer): Int64;
    function GetChapterTitle(Index: Integer): string;
  protected
    function ProbeFile:Boolean;
    procedure SeekFrame;
    procedure SaveAsBmp(Frame: PAVFrame;  AWidth,AHeight: Integer);
  public
    constructor Create;
    destructor Destroy;override;
    procedure NextFrame;
    property Active:Boolean read FActive write SetActive;
    property FileName:string read FFileName write SetFileName;

    property VideoEncoderName:string read FVideoEncoderName;
    property AudioEncoderName:string read FAudioEncoderName;

    property VideoWidth:integer read FVideoWidth;
    property VideoHeight:integer read FVideoHeight;
    property VideoFrameRate:Double read FVideoFrameRate;

    //Audio Information
    property SampleRate:integer read FSampleRate;
    property Channels:Integer read FChannels;
    property BytePerSample:Integer read FBytePerSample;

    property VideoBitrate:Integer read FVideoBitrate;
    property AudioBitrate:integer read FAudioBitrate;
    property Format:string read FFormat;

    property HasVideo:Boolean read FHasVideo;
    property HasAudio:Boolean read FHasAudio;
    property Duration: Double read FDuration;
    property Bitmap: TBitmap read FBitmap;
    property ThumbnailWidth:Integer read FThumbnailWidth write SetThumbnailWidth default 0;
    property ThumbnailHeight:Integer read FThumbnailHeight write SetThumbnailHeight default 0;
    property StartTime:Int64 read FStartTime;
    property EndTime:Int64 read FEndTime;
    property TimeStamp:Int64 read FTimeStamp write SetTimeStamp;
    property InputFormat:string read FInputFormat write SetInputFormat;
    property ChapterCount:Integer read GetChapterCount;
    property ChapterStart[Index:Integer]:Int64 read GetChapterStart;
    property ChapterEnd[Index:Integer]:Int64 read GetChapterEnd;
    property ChapterTitle[Index:Integer]:string read GetChapterTitle;
    property Handle:PAVFormatContext read fmt_ctx;
    property Eof:Boolean read FEof;
  end;

implementation

uses
  CmdUtils,
  avmem, avlib, dict, Math, errorno, SampleFmt ;

{ TAVProbe }
procedure CalcAspectSize(OrgWidth, OrgHeight:Integer;var MaxWidth,MaxHeight:Integer);
begin
  if OrgWidth>OrgHeight then
  begin
    MaxHeight:=(MaxWidth*OrgHeight) div OrgWidth;
  end
  else
  begin
    MaxWidth:=(MaxHeight * OrgWidth) div OrgHeight;
  end;
end;

constructor TAVProbe.Create;
begin
  LoadLibs;
  FBitmap:=TBitmap.Create;
end;

destructor TAVProbe.Destroy;
begin
  Active:=False;
  FBitmap.Free;
  inherited;
end;

procedure TAVProbe.NextFrame;
var
  NewWidth: Integer;
  NewHeight: Integer;
  packet: AVPacket;
  frameFinished: Integer;
  ret:Integer;
  d:double;
begin
  while (true) do
  begin
    ret :=av_read_frame(fmt_ctx, @packet);
    if ret= AVERROR(EAGAIN) then
      Continue;
    if ret= AVERROR_EOF then
    begin
      FTimeStamp:=fmt_ctx^.duration;
      FEof:=True;
      break;
    end;
    if (ret<0)  then
      break;
    if (packet.stream_index = FvideoStream) then
    begin
      avcodec_decode_video2(FCodecCtx, FFrame, @frameFinished, @packet);
      if (frameFinished <> 0) then
      begin
        Inc(FFrame^.data[0], FFrame^.linesize[0] * (FCodecCtx^.height - 1));
        FFrame^.linesize[0] := FFrame^.linesize[0] * (-1);

        Inc(FFrame^.data[1], FFrame^.linesize[1] * ((FCodecCtx^.height shr FVSub)  - 1));
        FFrame^.linesize[1] := FFrame^.linesize[1] * (-1);

        Inc(FFrame^.data[2], FFrame^.linesize[2] * ((FCodecCtx^.height shr FVSub) - 1));
        FFrame^.linesize[2] := FFrame^.linesize[2] * (-1);

        sws_scale(FSwsCtx, @FFrame^.data[0], @FFrame^.linesize[0], 0,
          FCodecCtx^.height, @FFrameRGB^.data[0], @FFrameRGB^.linesize[0]);

        NewWidth := FRealWidth;
        NewHeight := FRealHeight;
        CalcAspectSize(FCodecCtx^.Width, FCodecCtx^.height, NewWidth, NewHeight);

        FBitmap.PixelFormat := pf32bit;

        FBitmap.Width := NewWidth;
        FBitmap.height := NewHeight;
        FBitmap.Canvas.Brush.Color:=clBlack;
        FBitmap.Canvas.FillRect(Rect(0,0, FBitmap.Width, FBitmap.Height));

        SaveAsBmp(FFrameRGB, NewWidth, NewHeight);
        av_free_packet(@packet);

        //Update Position
        d:=av_q2d(fmt_ctx^.streams[FVideoStream]^.time_base);
        if (packet.pts<>AV_NOPTS_VALUE) then
          FTimeStamp:=Trunc(d*packet.pts*AV_TIME_BASE);

        break;
      end;
    end;
    av_free_packet(@packet);
  end;
end;

function TAVProbe.GetChapterCount: Integer;
begin
  Result:=0;
  if Active then
  begin
    Result:=fmt_ctx^.nb_chapters;
  end;
end;

function TAVProbe.GetChapterEnd(Index: Integer): Int64;
begin
  result:=0;
  if (Index<0) or (Index>=ChapterCount) then
    raise Exception.Create('Index out of range');
  if Active then
  begin
    Result:=Int64(Round(fmt_ctx^.chapters[Index]._end*av_q2d(fmt_ctx^.chapters[Index].time_base)*AV_TIME_BASE));
  end;
end;

function TAVProbe.GetChapterStart(Index: Integer): Int64;
begin
  Result:=0;
  if (Index<0) or (Index>=ChapterCount) then
    raise Exception.Create('Index out of range');
  if Active then
  begin
    Result:=Int64(Round(fmt_ctx^.chapters[Index].start*av_q2d(fmt_ctx^.chapters[Index].time_base)*AV_TIME_BASE));
  end;
end;

function TAVProbe.GetChapterTitle(Index: Integer): string;
begin
  Result:='';
  if (Index<0) or (Index>=ChapterCount) then
    raise Exception.Create('Index out of range');
  if Active then
  begin
    Result:=SysUtils.Format('track %d', [Index+1]);//fmt_ctx^.chapters[Index].metadata;
  end;
end;

procedure TAVProbe.CloseFile;
begin
  if Assigned(FSwsCtx) then
  begin
    sws_freeContext(FSwsCtx);
    FSwsCtx:=nil;
  end;

  if Assigned(FFrame) then
  begin
    av_free(FFrame);
    FFrame:=nil;
  end;

  if Assigned(FFrameRGB) then
  begin
    av_free(FFrameRGB);
    FFrameRGB:=nil;
  end;

  if Assigned(FCodecCtx) then
  begin
    avcodec_close(FCodecCtx);
    FCodecCtx:=nil;
  end;

  if Assigned(buf_to_free) then
  begin
    av_free(buf_to_free);
    buf_to_free:=nil;
  end;
  if Assigned(fmt_ctx) then
  begin
    avformat_close_input(fmt_ctx);
    fmt_ctx := nil;
  end;
end;

procedure TAVProbe.CheckCodecOfStream(stream: PAVStream);
var
  codec: PAVCodec;
  bits_per_sample:integer;
  options:PAVDictionary;
begin
  codec := avcodec_find_decoder(stream^.codec^.codec_id);
  options:=nil;
  if not Assigned(codec) then
    raise Exception.CreateFmt('Unsupported codec(id=%d) for input stream %d', [Ord(stream^.codec^.codec_id), stream^.index])
  else if (avcodec_open2(stream^.codec, codec,options) < 0) then
    raise Exception.CreateFmt('Error while opening codec for input stream %d', [stream^.index]);

  case stream^.codec^.codec_type of
    AVMEDIA_TYPE_VIDEO:
      begin
        FVideoEncoderName:=String(AnsiString(codec^.name));
//        if stream^.codec^.width<>0 then
//        begin
          FVideoWidth:=stream^.codec^.width;
          FVideoHeight:=stream^.codec^.height;
          FVideoBitrate:=stream^.codec^.bit_rate;
          FVideoFrameRate:=av_q2d(stream^.r_frame_rate);
//        end;

      end;
    AVMEDIA_TYPE_AUDIO:
      begin
        FAudioEncoderName:=String(AnsiString(codec^.name));
//        if stream^.codec^.sample_rate<>0 then
//        begin
          FSampleRate:=stream^.codec^.sample_rate;
          FChannels:=stream^.codec^.channels;
          FBytePerSample:=av_get_bytes_per_sample(stream^.codec.sample_fmt);
          bits_per_sample := av_get_bits_per_sample(stream^.codec^.codec_id);
          if bits_per_sample<>0 then
            FAudioBitrate := stream^.codec^.sample_rate * stream^.codec^.channels * bits_per_sample
          else
            FAudioBitrate := stream^.codec^.bit_rate;
//        end;
      end;
    else
      Assert(False);
  end;
  avcodec_close(stream^.codec);
end;

function TAVProbe.ProbeFile:Boolean;
var
  err,i:integer;
  stream:PAVStream;
  PictureSize:Integer;
  ret:Integer;
  NewWidth,NewHeight:Integer;
  pFormat:PAVInputFormat;
  format_opts, codec_opts:PAVDictionary;
  orig_nb_streams:Integer;
  opts:PPAVDictionary;
begin
  //fmt_ctx := avformat_alloc_context();
  Result:=True;
  pFormat:=nil;
  if Trim(InputFormat)<>EmptyStr then
    pFormat:=av_find_input_format(PAnsiChar(AnsiString(InputFormat)));
  format_opts:=nil;
  codec_opts:=nil;
  err :=avformat_open_input(fmt_ctx, PUTF8String(UTF8String(filename)), pFormat, format_opts);
  if (err < 0)  then
    Exit(False);

  FFormat:=AnsiString(fmt_ctx^.iformat^.name);

  opts := setup_find_stream_info_opts(fmt_ctx, codec_opts, avcodec_opts);
  orig_nb_streams := fmt_ctx^.nb_streams;

  //* fill the streams in the format context */
  err := avformat_find_stream_info(fmt_ctx, opts);
  if (err  < 0) then
  begin
    CloseFile();
    Exit(False);
  end;

  for i:=0 to orig_nb_streams -1 do
  begin
    av_dict_free(opts[i]);
  end;

  //dump_format(fmt_ctx, 0, filename, 0);

  //* bind a decoder to each input stream */
  FHasVideo:=False;
  FHasAudio:=False;
  FVideoStream:=av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,nil, 0) ;
  if FVideoStream>=0 then
  begin
    stream := fmt_ctx^.streams[FVideoStream];
    FHasVideo:=True;
    CheckCodecOfStream(stream);
  end;

  i :=av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_AUDIO,
                                -1, FVideoStream, nil, 0);
  if i >=0 then
  begin
    FHasAudio:=true;
    stream := fmt_ctx^.streams[i];
    CheckCodecOfStream(stream);
  end;

  if fmt_ctx^.start_time <> AV_NOPTS_VALUE then
    FStartTime := fmt_ctx^.start_time;

  FDuration := fmt_ctx^.Duration / AV_TIME_BASE;

  FEndtime:=FStartTime+fmt_ctx^.Duration;

  if FVideoStream>=0 then
  begin
    FCodecCtx := fmt_ctx^.streams[FVideoStream]^.codec;

    FCodec := avcodec_find_decoder(FCodecCtx^.codec_id);

    if (FCodec = nil) then
    begin
      // ErrorDlg('decoder find failed!');
      Exit;
    end;

    ret:= avcodec_open2(FCodecCtx, FCodec, opts^);
    if ( ret < 0) then
    begin
      // ErrorDlg('decoder open failed!');
      Exit;
    end;

    FFrame := avcodec_alloc_frame();
    FFrameRGB := avcodec_alloc_frame();

    if ((FFrame = nil) or (FFrameRGB = nil)) then
    begin
      // ErrorDlg('alloc frame failed!');
      Exit;
    end;

    if FThumbnailWidth=0 then
      FRealWidth := FCodecCtx^.width
    else
      FRealWidth:=FThumbnailWidth;

    if FThumbnailHeight=0 then
      FRealHeight:=FCodecCtx^.height
    else
      FRealHeight:=FThumbnailHeight;

    PictureSize := avpicture_get_size(AV_PIX_FMT_RGB32, FRealWidth,// FCodecCtx^.Width,
      //FCodecCtx^.height);
      FRealHeight);

    buf_to_free := av_malloc(PictureSize);

    if (buf_to_free = nil) then
    begin
      // ErrorDlg('buffer alloc failed!');
      Exit;
    end;
    NewWidth:=FRealWidth;
    NewHeight:=FRealHeight;
    CalcAspectSize(FCodecCtx^.Width, FCodecCtx^.height, NewWidth, NewHeight);

    avpicture_fill(PAVPicture(FFrameRGB), buf_to_free, AV_PIX_FMT_RGB32, NewWidth,//FCodecCtx^.Width,
      //FCodecCtx^.height);
      NewHeight);

    avcodec_get_chroma_sub_sample(FCodecCtx^.pix_fmt, @FHSub, @FVSub);

    FSwsCtx := sws_getContext(FCodecCtx^.Width, FCodecCtx^.height,
      FCodecCtx^.pix_fmt, NewWidth, NewHeight, AV_PIX_FMT_RGB32,
      SWS_BILINEAR, nil, nil, nil);
    SeekFrame;
  end;
end;

procedure TAVProbe.SaveAsBmp(Frame: PAVFrame; AWidth,AHeight : Integer);
var
  P: PByte;
begin
  P := FBitmap.ScanLine[FBitmap.height - 1];
  Move(Frame^.data[0]^, P^, AWidth * AHeight * 4);
  //draw bitmap to FBitmap;
end;

procedure TAVProbe.SeekFrame;
var
  AtimeStamp:Int64;
  ret:Integer;
begin
  Atimestamp := FStartTime+FTimeStamp;
  if Atimestamp <> 0 then
  begin
    ret := avformat_seek_file(fmt_ctx, -1, Low(Int64), AtimeStamp, Min(AtimeStamp, fmt_ctx^.duration), 0);
    if (ret < 0) then
    begin
      //ErrorDlg(Format('could not seek file %s',[FFileName]));
      Exit;
    end
    else
      avcodec_flush_buffers(FCodecCtx);
  end;
  NextFrame;
end;

procedure TAVProbe.SetActive(const Value: Boolean);
begin
  if (FActive=Value) then
    Exit;

  FEof:=False;
  if Value then
  begin
    if not ProbeFile() then
      Exit;
  end
  else if Assigned(fmt_ctx) then
  begin
    CloseFile;
  end;

  FActive := Value;
end;

procedure TAVProbe.SetFileName(const Value: string);
begin
  FFileName := Value;
end;

procedure TAVProbe.SetInputFormat(const Value: string);
begin
  FInputFormat := Value;
end;

procedure TAVProbe.SetThumbnailHeight(const Value: Integer);
begin
  FThumbnailHeight := Value;
end;

procedure TAVProbe.SetThumbnailWidth(const Value: Integer);
begin
  FThumbnailWidth := Value;
end;

procedure TAVProbe.SetTimeStamp(const Value: Int64);
begin
  if Value<0 then
    Exit;
  if Value>EndTime then
    Exit;
  FTimeStamp := Value;
  SeekFrame;
end;

end.
