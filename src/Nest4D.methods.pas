unit Nest4D.methods;

interface

type
  TNest4DMethodTypes = (fhGET, fhPOST, fhPUT, fhDELETE, fhPATCH);

  TNest4DMethod = class(TCustomAttribute)
  private
    FMethod: TNest4DMethodTypes;
    FRoute : String;
  public
    property Method: TNest4DMethodTypes read FMethod;
    property Route : String read FRoute;
  end;

  GET = class(TNest4DMethod)
  public
    constructor Create(const ARoute: String = '');
  end;

  POST = class(TNest4DMethod)
  public
    constructor Create(const ARoute: String = '');
  end;

  PUT = class(TNest4DMethod)
  public
    constructor Create(const ARoute: String = '');
  end;

  DELETE = class(TNest4DMethod)
  public
    constructor Create(const ARoute: String = '');
  end;

  PATCH = class(TNest4DMethod)
  public
    constructor Create(const ARoute: String = '');
  end;

implementation

{ GET }

constructor GET.Create(const ARoute: String);
begin
  FMethod := TNest4DMethodTypes.fhGET;
  FRoute  := ARoute;
end;

{ POST }

constructor POST.Create(const ARoute: String = '');
begin
  FMethod := TNest4DMethodTypes.fhPOST;
  FRoute  := ARoute;
end;

{ PUT }

constructor PUT.Create(const ARoute: String = '');
begin
  FMethod := TNest4DMethodTypes.fhPUT;
  FRoute  := ARoute;
end;

{ DELETE }

constructor DELETE.Create(const ARoute: String = '');
begin
  FMethod := TNest4DMethodTypes.fhDELETE;
  FRoute  := ARoute;
end;

{ PATCH }

constructor PATCH.Create(const ARoute: String = '');
begin
  FMethod := TNest4DMethodTypes.fhPATCH;
  FRoute  := ARoute;
end;

end.
