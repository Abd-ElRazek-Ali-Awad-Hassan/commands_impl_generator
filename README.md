# CommandsImplGenerator

## A package that generates impl for query methods.

### an example 

```
@GenerateForCommands()
class SomeRepo with _$CommandsImplMixin {
  SomeRepo(InternetConnectionChecker internetConnectionChecker) {
    _$setInternetConnectionChecker(internetConnectionChecker);
  }
  
  @Command()
  Future<Either<Failure, void>> signIn() async {
    return await _$signIn(
      () async => Right(await _api.signIn()),
    );
  }
}
```