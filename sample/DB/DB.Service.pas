unit DB.Service;

interface

uses
  Nest4D.Attrs,
  Nest4D.Types;

type

  [Injectable(stSingleton)]
  TConfigService = Class

  public
    function GetConfig: String;
  End;

  [Injectable(stRequest)]
  TDBService = Class
  private
    FConfig: TConfigService;
  public
    constructor Create([Inject] const configService: TConfigService);
  End;

implementation

{ TDBService }

constructor TDBService.Create(const configService: TConfigService);
begin
  FConfig := configService;
end;

{ TConfigService }

function TConfigService.GetConfig: String;
begin
  Result := 'DEU CERTO POrRAAA';
end;

end.
