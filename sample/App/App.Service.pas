unit App.Service;

interface

uses
  Nest4D.Attrs,
  Nest4D.Types,
  DB.Service;

type

  [Injectable(stRequest)]
  TAppService = Class
  private
    FDBService: TDBService;
  public
    constructor Create([Inject] const dbService: TDBService);
  End;

implementation

{ TAppService }

constructor TAppService.Create(const dbService: TDBService);
begin
  FDBService := dbService;
end;

end.
