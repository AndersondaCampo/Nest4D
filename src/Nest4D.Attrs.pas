unit Nest4D.Attrs;

interface

uses
  Nest4D.Types;

type
  Injectable = Class(TCustomAttribute)
  private
    FScope: TScopeType;
  public
    property Scope: TScopeType read FScope;
    constructor Create(const Scope: TScopeType);
  End;

  Inject = Class(TCustomAttribute)
  End;

  Controller = Class(TCustomAttribute)
  private
    FPath: String;
  public
    property Path: String read FPath;
    constructor Create(const Path: String = '');
  End;

implementation

{ Injectable }

constructor Injectable.Create(const Scope: TScopeType);
begin
  FScope := Scope;
end;

{ Controller }

constructor Controller.Create(const Path: String);
begin
  FPath := Path;
end;

end.
