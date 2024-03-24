import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:commands_impl_annotation/commands_impl_annotation.dart';
import 'package:commands_impl_generator/src/utils.dart';
import 'package:source_gen/source_gen.dart';

class CommandsImplGenerator
    extends GeneratorForAnnotation<GenerateForCommands> {
  const CommandsImplGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (annotation.isNull) {
      throw InvalidGenerationSource(
        'The source annotation should be set!',
        element: element,
      );
    }
    if (element is! ClassElement) {
      throw InvalidGenerationSource(
        "'$GenerateForCommands()' only support classes",
        element: element,
      );
    }

    return (StringBuffer()
          ..writeAll([
            _buildMixinDeclaration(),
            _buildConnectionCheckerInstanceDeclaration(),
            _buildConnectionCheckerInstanceSetter(),
            ...Utils.methodsAnnotatedWith<Command>(element.methods).map(
              (e) => '${_buildMethod(e)}\n',
            ),
            _buildExecuteActionIfHasInternetAccess(),
            _buildMapExceptionToFailureOn(),
            '}\n',
          ]))
        .toString();
  }

  String _buildMixinDeclaration() => 'mixin _\$CommandsImplMixin {\n'
      '\n';

  String _buildMethod(MethodElement element) {
    bool isCommandWithCaching = Utils.getFirstAnnotationOn<Command>(element)!
        .getField('withCaching')!
        .toBoolValue()!;

    if (isCommandWithCaching) {
      return _buildCommandWithCachingImplFor(element);
    }
    return _buildCommandWithoutCachingImplFor(element);
  }

  String _buildCommandWithCachingImplFor(MethodElement element) {
    return 'Future<Either<Failure, void>> _\$${element.name}<ReturnType>({\n'
        '  required Future<ReturnType> Function() getFromRemote,\n'
        '  required Future<void> Function(ReturnType) saveOnCache,\n'
        '}) async {\n'
        '  return await ${_getMapExceptionToFailureReferenceFor(element)}'
        '  (callback: () async {\n'
        '    return _\$executeCommandIfHasInternetAccess(\n'
        '      command: () async {\n'
        '        final value = await getFromRemote();\n'
        '        return Right(await saveOnCache(value));\n'
        '      },\n'
        '    );\n'
        '  });\n'
        '}\n';
  }

  String _buildCommandWithoutCachingImplFor(MethodElement element) {
    return '${element.returnType} _\$${element.name}(\n'
        ' ${element.returnType} Function() callback,\n'
        ') async =>\n'
        '_\$executeCommandIfHasInternetAccess(\n'
        'command: () => ${_getMapExceptionToFailureReferenceFor(element)}'
        '(callback: callback),\n'
        ');\n';
  }

  String _getMapExceptionToFailureReferenceFor(MethodElement element) {
    final mapExceptionToFailure = Utils.getPassedFunctionToAnnotation(
      Utils.getFirstAnnotationOn<Command>(element),
      'mapExceptionToFailure',
    );

    return switch (mapExceptionToFailure) {
      (null) => '_\$mapExceptionToFailureOn',
      (ExecutableElement e) => Utils.getFunctionReferenceAsStringFor(e),
    };
  }

  String _buildConnectionCheckerInstanceDeclaration() =>
      'late final InternetConnectionChecker _checker;\n\n';

  String _buildConnectionCheckerInstanceSetter() =>
      'void _\$setInternetConnectionChecker(InternetConnectionChecker checker) =>'
      ' _checker = checker;'
      '\n\n';

  String _buildExecuteActionIfHasInternetAccess() =>
      'Future<Either<Failure, void>> _\$executeCommandIfHasInternetAccess({\n'
      'required Future<Either<Failure, void>> Function() command,\n'
      '}) async {\n'
      'if (!await _checker.hasInternetAccess) {\n'
      'return Left(NetworkFailure());\n'
      '}\n'
      'return await command();\n'
      '}\n';

  String _buildMapExceptionToFailureOn() =>
      'Future<Either<Failure, void>> _\$mapExceptionToFailureOn({\n'
      'required Future<Either<Failure, void>> Function() callback,\n'
      '}) async {\n'
      'try {\n'
      'return await callback();\n'
      '} on NetworkException {\n'
      'return Left(NetworkFailure());\n'
      '} on ServerException catch (exception) {\n'
      'return Left(ServerFailure(message: exception.message));\n'
      '} on CacheException catch (exception) {\n'
      'return Left(CacheFailure(message: exception.message));\n'
      '}\n'
      '}\n';
}
