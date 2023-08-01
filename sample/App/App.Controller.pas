unit App.Controller;

interface

uses
  Nest4D.Attrs,
  Nest4D.Methods,
  DB.Service,
  Nest4D;

type

  [Controller('api')]
  TAppController = Class
  private
    FConfigService: TConfigService;
  public
    constructor Create([Inject] const ConfigService: TConfigService);

    [GET('name')]
    function getControllerName: String;

    [GET('config')]
    function getConfig: String;

    [GET('headers')]
    function getHeaders([Request] req: TReq): String;
  End;

implementation

uses
  System.SysUtils;

{ TAppController }

constructor TAppController.Create(const ConfigService: TConfigService);
begin
  FConfigService := ConfigService;
end;

function TAppController.getConfig: String;
begin
  Result := FConfigService.getConfig;
end;

function TAppController.getControllerName: String;
begin
  Result := Self.ClassName;
end;

function TAppController.getHeaders(req: TReq): String;
begin
  Result := req.Headers.Content.Text;
end;

end.
