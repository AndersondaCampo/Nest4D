unit Nest4D;

interface

uses
  System.Generics.Collections,
  Horse,
  Nest4D.route,
  Nest4D.methods;

type
  TReq  = THorseRequest;
  TRes  = THorseResponse;
  TNext = THorseCallback;

  Body = Class(TCustomAttribute);
  Param = Class(TCustomAttribute);
  Header = Class(TCustomAttribute);
  Query = Class(TCustomAttribute);
  Request = Class(TCustomAttribute);
  Response = Class(TCustomAttribute);

  TNest4D = class(TObject)
  private
    class var FClasses       : TList<TClass>;
    class var FRoutesHandlers: TDictionary<String, TPair<String, TClass>>;

    class procedure StartVars();
    class procedure ClearVars();
  public
    class procedure RegisterController(controller: TClass); overload;
    class procedure RegisterController(controllers: array of TClass); overload;
    class procedure Bootstrap();
    class procedure Start(port: Integer; proc: TProc); overload;
    class procedure Start(port: Integer); overload;
  end;

procedure RequestHandler(req: TReq; res: TRes);

implementation

uses
  System.Rtti,
  System.TypInfo,
  System.SysUtils,
  System.StrUtils,
  System.Variants,
  System.JSON,
  Horse.Callback;

{ TNest4D }

class procedure TNest4D.RegisterController(controller: TClass);
begin
  TNest4D.FClasses.Add(controller);
end;

class procedure TNest4D.Bootstrap;
var
  controller: TClass;

  ctx    : TRttiContext;
  rType  : TRttiType;
  rMethod: TRttiMethod;
  attr   : TCustomAttribute;

  controllerPath: String;
  Lroute         : String;
  routes: Array of String;
begin
  ctx := TRttiContext.Create;
  try
    for controller in TNest4D.FClasses do
    begin
      rType := ctx.GetType(controller);
      if rType.GetAttributes[0] is Route then
      begin
        controllerPath := Route(rType.GetAttributes[0]).Path
      end;

      for rMethod in rType.GetMethods do
      begin
        for attr in rMethod.GetAttributes do
        begin
          if attr is TNest4DMethod then
          begin
            Lroute := '/' + controllerPath;
            if TNest4DMethod(attr).route <> '' then
              Lroute := Lroute + '/' + TNest4DMethod(attr).route;

            Lroute := Lroute.Replace('//', '/');

            FRoutesHandlers.Add(Lroute, TPair<String, TClass>.Create(rMethod.Name, controller));

            SetLength(routes, Length(routes) + 1);
            routes[High(routes)] := Lroute;

            case TNest4DMethod(attr).Method of
              fhGET:
                THorse.Get(Lroute, RequestHandler);
              fhPOST:
                THorse.Post(Lroute, RequestHandler);
              fhPUT:
                THorse.Put(Lroute, RequestHandler);
              fhDELETE:
                THorse.Delete(Lroute, RequestHandler);
              fhPATCH:
                THorse.Patch(Lroute, RequestHandler);
            end;
          end;
        end;
      end;
    end;

    Writeln('Routes');
    for Lroute in routes do
    begin
      Writeln('- '+ Lroute);
    end;
    Writeln('');
  finally
    ctx.Free;
  end;
end;

class procedure TNest4D.RegisterController(controllers: array of TClass);
var
  controller: TClass;
begin
  for controller in controllers do
  begin
    RegisterController(controller);
  end;
end;

class procedure TNest4D.Start(port: Integer; proc: TProc);
begin
  THorse.Port := port;
  THorse.Listen(proc);
end;

class procedure TNest4D.Start(port: Integer);
begin
  THorse.Port := port;
  THorse.Listen;
end;

class procedure TNest4D.StartVars;
begin
  FClasses        := TList<TClass>.Create;
  FRoutesHandlers := TDictionary < String, TPair < String, TClass >>.Create;
end;

class procedure TNest4D.ClearVars;
begin
  FClasses.Free;
  FRoutesHandlers.Free;
end;

procedure RequestHandler(req: TReq; res: TRes);

  function StringToInteger(const AValue: string): Integer;
  begin
    Result := StrToIntDef(AValue, 0);
  end;

  function StringToDouble(const AValue: string): Double;
  begin
    Result := StrToFloatDef(AValue, 0.0);
  end;

  function StringToBoolean(const AValue: string): Boolean;
  begin
    Result := (LowerCase(AValue) = 'true') or (AValue = '1');
  end;

var
  ctx    : TRttiContext;
  rType  : TRttiType;
  rMethod: TRttiMethod;
  rParam : TRttiParameter;
  rAttr  : TCustomAttribute;
  obj    : TObject;
  pair   : TPair<String, TClass>;
  lroute  : String;
  i      : Integer;

  params: Array of TValue;
  returnValue: TValue;
begin
  try
    lroute := req.PathInfo;

    if Pos('?', lroute) > 0 then
      lroute := Copy(lroute, 1, Pos('?', lroute) - 1);

    if req.Params.Count > 0 then
    begin
      for i := 0 to req.Params.Count - 1 do
      begin
        lroute := StringReplace(lroute, req.Params.Dictionary.Values.ToArray[i],
          ':' + req.Params.Dictionary.Keys.ToArray[i], [rfReplaceAll]);
      end;
    end;

    if TNest4D.FRoutesHandlers.TryGetValue(lroute, pair) then
    begin
      ctx := TRttiContext.Create;
      try
        rType := ctx.GetType(pair.Value);

        rMethod := rType.GetMethod('create');
        if rMethod.IsConstructor then
          obj := rMethod.Invoke(rType.AsInstance.MetaclassType.Create, []).AsObject
        else
          obj := rType.AsInstance.MetaclassType.Create;

        try
          rMethod := rType.GetMethod(pair.Key);

          for rParam in rMethod.GetParameters do
          begin
            for rAttr in rParam.GetAttributes do
            begin
              if rAttr is Body then
              begin
                params[High(params)] := req.Body;
                Continue;
              end;

              if rAttr is Param then
              begin
                SetLength(params, Length(params) + 1);

                if rParam.ParamType.Handle = TypeInfo(Integer) then
                  params[High(params)] := StringToInteger(req.Params[rParam.Name])
                else if rParam.ParamType.Handle = TypeInfo(Double) then
                  params[High(params)] := StringToDouble(req.Params[rParam.Name])
                else if rParam.ParamType.Handle = TypeInfo(Boolean) then
                  params[High(params)] := StringToBoolean(req.Params[rParam.Name])
                else
                  params[High(params)] := req.Params[rParam.Name];

                Continue;
              end;

              if rAttr is Header then
              begin
                SetLength(params, Length(params) + 1);
                params[High(params)] := req.Headers[rParam.Name];
                Continue;
              end;

              if rAttr is Query then
              begin
                SetLength(params, Length(params) + 1);
                params[High(params)] := req.Query[rParam.Name];
                Continue;
              end;

              if rAttr is Request then
              begin
                SetLength(params, Length(params) + 1);
                params[High(params)] := TReq(req);
                Continue;
              end;

              if rAttr is Response then
              begin
                SetLength(params, Length(params) + 1);
                params[High(params)] := TRes(res);
                Continue;
              end;
            end;

          end;

          returnValue := rMethod.Invoke(obj, params);
          if (rMethod.MethodKind = mkFunction) then
          begin
            if (returnValue.IsObject and (returnValue.AsObject is TJSONValue)) then
            begin
              res.Send(returnValue.AsObject.ToString);
              // Destroy??
            end
              { TODO : Criar tratativa para tornar possível o retorno de qualquer tipo de objeto }
//            else if (returnValue.IsArray) then
//              returnValue.Cast(TypeInfo(returnValue)).ExtractRawData(pointer)
            else
              res.Send(VarToStrDef(returnValue.AsVariant, ''));
          end;
        finally
          obj.Free;
        end;

      finally
        ctx.Free;
      end;
    end;
  except
    on E: Exception do
    begin
      res.Status(500).Send(E.Message);
    end;
  end;
end;

initialization

TNest4D.StartVars();

finalization

TNest4D.ClearVars();

end.
