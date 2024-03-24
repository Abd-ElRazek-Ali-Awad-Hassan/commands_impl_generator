import 'dart:core';

import 'package:commands_impl_annotation/commands_impl_annotation.dart';
import 'package:failures/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldThrow('The source annotation should be set!')
class AClassNotAnnotated {}

@ShouldThrow("'GenerateForCommands()' only support classes")
@GenerateForCommands()
void aFunctionNotAClass() {}

@ShouldThrow("'GenerateForCommands()' only support classes")
@GenerateForCommands()
const double aVariableNotAClass = 3.14;

@ShouldGenerate(
  'mixin _\$CommandsImplMixin {\n'
  '  late final InternetConnectionChecker _checker;\n'
  '\n'
  '  void _\$setInternetConnectionChecker(InternetConnectionChecker checker) =>\n'
  '      _checker = checker;\n'
  '\n'
  '  Future<Either<Failure, void>> _\$executeCommandIfHasInternetAccess({\n'
  '    required Future<Either<Failure, void>> Function() command,\n'
  '  }) async {\n'
  '    if (!await _checker.hasInternetAccess) {\n'
  '      return Left(NetworkFailure());\n'
  '    }\n'
  '    return await command();\n'
  '  }\n'
  '\n'
  '  Future<Either<Failure, void>> _\$mapExceptionToFailureOn({\n'
  '    required Future<Either<Failure, void>> Function() callback,\n'
  '  }) async {\n'
  '    try {\n'
  '      return await callback();\n'
  '    } on NetworkException {\n'
  '      return Left(NetworkFailure());\n'
  '    } on ServerException catch (exception) {\n'
  '      return Left(ServerFailure(message: exception.message));\n'
  '    } on CacheException catch (exception) {\n'
  '      return Left(CacheFailure(message: exception.message));\n'
  '    }\n'
  '  }\n'
  '}\n',
  contains: true,
)
@GenerateForCommands()
abstract class GenerateMixin {
  Future<Either<Failure, void>> aFunctionNotAnnotated();
}

@ShouldGenerate(
  '  Future<Either<Failure, void>> _\$doSomethingWithoutCaching(\n'
  '    Future<Either<Failure, void>> Function() callback,\n'
  '  ) async =>\n'
  '      _\$executeCommandIfHasInternetAccess(\n'
  '        command: () => _\$mapExceptionToFailureOn(callback: callback),\n'
  '      );\n'
  '\n'
  '  Future<Either<Failure, void>> _\$doSomethingWithCaching<ReturnType>({\n'
  '    required Future<ReturnType> Function() getFromRemote,\n'
  '    required Future<void> Function(ReturnType) saveOnCache,\n'
  '  }) async {\n'
  '    return await _\$mapExceptionToFailureOn(callback: () async {\n'
  '      return _\$executeCommandIfHasInternetAccess(\n'
  '        command: () async {\n'
  '          final value = await getFromRemote();\n'
  '          return Right(await saveOnCache(value));\n'
  '        },\n'
  '      );\n'
  '    });\n'
  '  }\n',
  contains: true,
)
@GenerateForCommands()
abstract class GenerateCommandsImpl {
  @Command()
  Future<Either<Failure, void>> doSomethingWithoutCaching() async =>
      const Right(null);

  @Command(withCaching: true)
  Future<Either<Failure, void>> doSomethingWithCaching() async {
    return _$doSomethingWithCaching(
      getFromRemote: () async => Future.value(1),
      saveOnCache: (value) async {},
    );
  }

  Future<Either<Failure, void>> _$doSomethingWithCaching<ReturnType>({
    required Future<ReturnType> Function() getFromRemote,
    required Future<void> Function(ReturnType) saveOnCache,
  });
}

@ShouldGenerate(
  '  Future<Either<Failure, void>> _\$doSomethingWithoutCaching(\n'
  '    Future<Either<Failure, void>> Function() callback,\n'
  '  ) async =>\n'
  '      _\$executeCommandIfHasInternetAccess(\n'
  '        command: () => GenerateCommandsWithCustomExceptionMappingImpl\n'
  '            .mapExceptionToFailureOn(callback: callback),\n'
  '      );\n'
  '\n'
  '  Future<Either<Failure, void>> _\$doSomethingWithCaching<ReturnType>({\n'
  '    required Future<ReturnType> Function() getFromRemote,\n'
  '    required Future<void> Function(ReturnType) saveOnCache,\n'
  '  }) async {\n'
  '    return await GenerateCommandsWithCustomExceptionMappingImpl\n'
  '        .mapExceptionToFailureOn(callback: () async {\n'
  '      return _\$executeCommandIfHasInternetAccess(\n'
  '        command: () async {\n'
  '          final value = await getFromRemote();\n'
  '          return Right(await saveOnCache(value));\n'
  '        },\n'
  '      );\n'
  '    });\n'
  '  }\n',
  contains: true,
)
@GenerateForCommands()
abstract class GenerateCommandsWithCustomExceptionMappingImpl {
  @Command(mapExceptionToFailure: mapExceptionToFailureOn)
  Future<Either<Failure, void>> doSomethingWithoutCaching() async =>
      const Right(null);

  @Command(withCaching: true, mapExceptionToFailure: mapExceptionToFailureOn)
  Future<Either<Failure, void>> doSomethingWithCaching() async {
    return _$doSomethingWithCaching(
      getFromRemote: () async => Future.value(1),
      saveOnCache: (value) async {},
    );
  }

  Future<Either<Failure, void>> _$doSomethingWithCaching<ReturnType>({
    required Future<ReturnType> Function() getFromRemote,
    required Future<void> Function(ReturnType) saveOnCache,
  });

  static Future<Either<Failure, void>> mapExceptionToFailureOn({
    required Future<Either<Failure, void>> Function() callback,
  }) async {
    try {
      return await callback();
    } on FormatException {
      return Left(ServerFailure());
    }
  }
}
