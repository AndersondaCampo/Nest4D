unit Nest4D.route;

interface

type
  Route = class(TCustomAttribute)
  private
    FPath: string;
  public
    property Path: string read FPath;
    constructor Create(const APath: string);
  end;

implementation

constructor Route.Create(const APath: string);
begin
  FPath := APath;
end;

end.
