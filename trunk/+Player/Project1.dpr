program Project1;

uses
  Vcl.Forms,
  FH.BUFFER.FIFO in '../../../Injest/LIB/fhQueue/FH.BUFFER.FIFO.pas',
  FH.SYNC in '../../../Injest/LIB/FH.SYNC.pas',
  SDL2 in '../../../Injest/LIB/SDL/Pascal-SDL-2-Header/SDL2.pas',
  avutil in '../ffmpeg-20140810-git-e18d9d9/libavutil/avutil.pas',
  avcodec in '../ffmpeg-20140810-git-e18d9d9/libavcodec/avcodec.pas',
  avformat in '../ffmpeg-20140810-git-e18d9d9/libavformat/avformat.pas',
  swresample in '../ffmpeg-20140810-git-e18d9d9/libswresample/swresample.pas',
  postprocess in '../ffmpeg-20140810-git-e18d9d9/libpostproc/postprocess.pas',
  avdevice in '../ffmpeg-20140810-git-e18d9d9/libavdevice/avdevice.pas',
  swscale in '../ffmpeg-20140810-git-e18d9d9/libswscale/swscale.pas',
  Unit1 in 'Unit1.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
