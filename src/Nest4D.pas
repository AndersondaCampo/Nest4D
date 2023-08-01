unit Nest4D;

interface

uses
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  Nest4D.types,

  { }
  Horse;

type
  TReq  = THorseRequest;
  TRes  = THorseResponse;
  TNext = THorseCallback;

  Body     = Class(TCustomAttribute);
  Param    = Class(TCustomAttribute);
  Header   = Class(TCustomAttribute);
  Query    = Class(TCustomAttribute);
  Request  = Class(TCustomAttribute);
  Response = Class(TCustomAttribute);

  TInstance = Record
    &Class: TClass;
    &Type: TScopeType;
    instance: TObject;
  End;

  TNestModule = Class
  private
    FModules    : TArray<TClass>;
    FControllers: TArray<TClass>;
    FServices   : TArray<TClass>;
  public
    procedure SetModules(const Modules: TArray<TClass>);
    procedure SetControllers(const controllers: TArray<TClass>);
    procedure SetServices(const services: TArray<TClass>);
  End;

procedure Bootstrap(const module: TClass);

var
  injectables  : TDictionary<String, TInstance>;
  RoutesHandler: TDictionary<String, TPair<String, TClass>>;

implementation

uses
  System.JSON,
  System.SysUtils,
  System.Variants,
  Nest4D.Attrs,
  Nest4D.methods;

procedure RequestHandler(req: TReq; res: TRes);

  function ResolveCreateParams(const classe: TClass): TArray<TValue>;
  var
    ctx    : TRttiContext;
    rType  : TRttiType;
    rMethod: TRttiMethod;
    rParam : TRttiParameter;
    rAttr  : TCustomAttribute;
    i      : Integer;

    internalParams: TArray<TValue>;
    instance      : TInstance;
  begin
    SetLength(Result, 0);

    ctx := TRttiContext.Create;
    try
      rType   := ctx.GetType(classe);
      rMethod := rType.GetMethod('create');
      for rParam in rMethod.GetParameters do
      begin
        for rAttr in rParam.GetAttributes do
        begin
          if rAttr is Inject then
          begin
            SetLength(Result, Length(Result) + 1);
            // if (injectables[rParam.ParamType.Name].&Type = stSingleton) and not assigned(injectables[rParam.ParamType.Name].instance) then
            // begin
            //   rType := ctx.GetType(injectables[rParam.ParamType.Name].&Class);
            //   rMethod := rType.GetMethod('create');
            //   internalParams := ResolveCreateParams(injectables[rParam.ParamType.Name].&Class);
            //   injectables[rParam.ParamType.Name].instance := rMethod.Invoke(rType.AsInstance.MetaclassType.Create, internalParams);
            // end else if (injectables[rParam.ParamType.Name].&Type = stRequest) then
            // begin
            //   rType := ctx.GetType(injectables[rParam.ParamType.Name].&Class);
            //   rMethod := rType.GetMethod('create');
            //   internalParams := ResolveCreateParams(injectables[rParam.ParamType.Name].&Class);
            //   injectables[rParam.ParamType.Name].instance := rMethod.Invoke(rType.AsInstance.MetaclassType.Create, internalParams);
            // end;

            rType   := ctx.GetType(injectables[rParam.ParamType.Name].&Class);
            rMethod := rType.GetMethod('create');

            instance             := injectables[rParam.ParamType.Name];
            internalParams       := ResolveCreateParams(instance.&Class);
            instance.instance    := rMethod.Invoke(rType.AsInstance.MetaclassType.Create, internalParams).AsObject;
            Result[High(Result)] := instance.instance;
            //              injectables.AddOrSetValue(rParam.ParamType.Name, instance);
          end;
        end;
      end;
    finally
      ctx.Free;
    end;

  end;

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
  Lroute : String;
  i      : Integer;

  params     : Array of TValue;
  returnValue: TValue;
begin
  try
    Lroute := req.PathInfo;

    if Pos('?', Lroute) > 0 then
      Lroute := Copy(Lroute, 1, Pos('?', Lroute) - 1);

    if req.params.Count > 0 then
    begin
      for i := 0 to req.params.Count - 1 do
      begin
        Lroute := StringReplace(Lroute, req.params.Dictionary.Values.ToArray[i],
          ':' + req.params.Dictionary.Keys.ToArray[i], [rfReplaceAll]);
      end;
    end;

    if RoutesHandler.TryGetValue(Lroute, pair) then
    begin
      ctx := TRttiContext.Create;
      try
        rType := ctx.GetType(pair.Value);

        rMethod := rType.GetMethod('create');
        if rMethod.IsConstructor then
        begin
          obj := rMethod.Invoke(rType.AsInstance.MetaclassType.Create,
            ResolveCreateParams(rType.AsInstance.MetaclassType)).AsObject
        end
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
                  params[High(params)] := StringToInteger(req.params[rParam.Name])
                else
                  if rParam.ParamType.Handle = TypeInfo(Double) then
                    params[High(params)] := StringToDouble(req.params[rParam.Name])
                  else
                    if rParam.ParamType.Handle = TypeInfo(Boolean) then
                      params[High(params)] := StringToBoolean(req.params[rParam.Name])
                    else
                      params[High(params)] := req.params[rParam.Name];

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
            { TODO : Criar tratativa para tornar poss�vel o retorno de qualquer tipo de objeto }
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

procedure ProcessController(const obj: TClass);
var
  ctx    : TRttiContext;
  rType  : TRttiType;
  rMethod: TRttiMethod;
  attr   : TCustomAttribute;

  controllerPath: String;
  Lroute        : String;
  routes        : Array of String;
begin
  ctx := TRttiContext.Create;
  try
    rType := ctx.GetType(obj);
    if rType.GetAttributes[0] is Controller then
    begin
      controllerPath := Controller(rType.GetAttributes[0]).Path
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

          RoutesHandler.Add(Lroute, TPair<String, TClass>.Create(rMethod.Name, obj));

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

    for Lroute in routes do
    begin
      Writeln('- ' + Lroute);
    end;
    Writeln('');
  finally
    ctx.Free;
  end;
end;

procedure ProcessInjectable(const obj: TClass);
var
  rCtx   : TRttiContext;
  rType  : TRttiType;
  rAttr  : TCustomAttribute;
  rMethod: TRttiMethod;
  rParam : TRttiParameter;

  instance: TInstance;
begin
  rCtx := TRttiContext.Create;
  try
    rType := rCtx.GetType(obj);

    for rAttr in rType.GetAttributes do
    begin
      if rAttr is injectable then
      begin
        if not injectables.ContainsKey(rType.Name) then
        begin
          instance.&Class   := obj;
          instance.&Type    := (rAttr as injectable).Scope;
          instance.instance := nil;
          injectables.Add(rType.Name, instance);
        end;
      end;
    end;

    rMethod := rType.GetMethod('create');
    for rParam in rMethod.GetParameters do
    begin
      for rAttr in rParam.GetAttributes do
      begin
        if (rAttr is Inject) and rParam.ParamType.IsInstance then
          ProcessInjectable(rParam.ParamType.AsInstance.MetaclassType);
      end;
    end;

  finally
    rCtx.Free;
  end;
end;

procedure Bootstrap(const module: TClass);
var
  rCtx   : TRttiContext;
  rType  : TRttiType;
  rMethod: TRttiMethod;
  obj    : TObject;
  classe : TClass;
begin
  rCtx := TRttiContext.Create;
  try
    rType := rCtx.GetType(module);

    if not rType.AsInstance.MetaclassType.InheritsFrom(TNestModule) then
      raise Exception.Create('A module not inherites from TNestModule!');

    rMethod := rType.GetMethod('create');
    obj     := rMethod.Invoke(rType.AsInstance.MetaclassType.Create, []).AsObject;
    try
      for classe in (obj as TNestModule).FServices do
      begin
        ProcessInjectable(classe);
      end;

      for classe in (obj as TNestModule).FControllers do
      begin
        ProcessController(classe);
      end;

    finally
      obj.Free;
    end;
  finally
    rCtx.Free;
  end;
end;

{ TNestModule }

procedure TNestModule.SetControllers(const controllers: TArray<TClass>);
begin
  FControllers := controllers;
end;

procedure TNestModule.SetModules(const Modules: TArray<TClass>);
begin
  FModules := Modules;
end;

procedure TNestModule.SetServices(const services: TArray<TClass>);
begin
  FServices := services;
end;

initialization

injectables   := TDictionary<String, TInstance>.Create();
RoutesHandler := TDictionary < String, TPair < String, TClass >>.Create;

finalization

RoutesHandler.Free;
injectables.Free;

end.
