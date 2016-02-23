unit vf_test;

interface

uses
  System.SysUtils,
  avutil,
  avcodec,
  avfilter;

type
  PTestFilterContext = ^TTestFilterContext;
  TTestFilterContext = packed record
    mode : integer;
  end;

function vf_test_register: integer;

var
  FTestFilter   : TAVFilter;
  FTestInputs   : array of TAVFilterPad;
  FTestOutputs : array of TAVFilterPad;

implementation

function vf_test_register: integer;
begin
  result := avfilter_register(@FTestFilter);
end;

function filter_frame_input(inlink: PAVFilterLink; in_ : PAVFrame): Integer; cdecl;
begin
  result := 1
end;

function config_props_input(link: PAVFilterLink): Integer; cdecl;
begin
  writeln('config_props_input');
  result := 0;
end;

initialization

  setLength(FTestInputs,1);
  fillchar(FTestInputs[0], sizeof(TAVFilterPad), #0);
  FTestInputs[0].name         := PAnsiChar('default');
  FTestInputs[0].type_        := AVMEDIA_TYPE_VIDEO;
  FTestInputs[0].filter_frame := @filter_frame_input;
	FTestInputs[0].config_props := @config_props_input;

  setLength(FTestOutputs,1);
  fillchar(FTestOutputs[0], sizeof(TAVFilterPad), #0);
  FTestOutputs[0].name         := PAnsiChar('default');
  FTestOutputs[0].type_        := AVMEDIA_TYPE_VIDEO;

  fillchar(FTestFilter, sizeof(TAVFilter), #0);
  FTestFilter.name := PAnsiChar('ip-crypt');
  FTestFilter.description := PAnsiChar('ip-crypt descrition');
  FTestFilter.priv_size   := sizeof(TTestFilterContext);
  FTestFilter.inputs      := PAVFilterPad(FTestInputs);
  FTestFilter.outputs     := PAVFilterPad(FTestOutputs);


finalization

end.
