{-# LANGUAGE OverloadedStrings  #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Language.Swift.Quote.Pretty where

import Language.Swift.Quote.Syntax

import Data.Text.Lazy (Text, append)
import Text.PrettyPrint.Mainland

prettyPrint :: Module -> Text
prettyPrint m = append p "\n"
  where p = prettyLazyText 100 (ppr m)

ind = indent 2

instance Pretty Module where
  ppr (Module statements) = stack (map ppr statements)

instance Pretty Expression where
  ppr (Expression optTryOperator prefixExpression binaryExpressions) =
    ppr optTryOperator <+> ppr prefixExpression <+> spread (map ppr binaryExpressions)

instance Pretty PrefixExpression where
  ppr (PrefixOperator optPrefixOperator primaryExpression)
    = ppr optPrefixOperator <> ppr primaryExpression
  ppr (InOutExpression identifier) = string "&" <> string identifier

instance Pretty PostfixExpression where
  ppr (PostfixPrimary primaryExpression) = ppr primaryExpression
  ppr (PostfixOperator prefixExpression postfixOperator) = ppr prefixExpression <> ppr postfixOperator
  ppr (ExplicitMemberExpressionDigits postfixExpression digits) = ppr postfixExpression <> string digits
  ppr (ExplicitMemberExpressionIdentifier postfixExpression idG) = ppr postfixExpression <> ppr idG
  ppr (FunctionCallE functionCall) = ppr functionCall
  ppr (PostfixExpression4Initalizer postfixExpression) = ppr postfixExpression <> string ".init"
  ppr (PostfixSelf postfixExpression) = ppr postfixExpression <> string ".self"
  ppr (PostfixDynamicType postfixExpression) = ppr postfixExpression <> string ".dynamicType"
  ppr (PostfixForcedValue postfixExpression) = ppr postfixExpression <> string "!"
  ppr (PostfixOptionChaining postfixExpression) = ppr postfixExpression <> string "?"
  ppr (Subscript postfixExpression expressions) = ppr postfixExpression <> brackets (commasep (map ppr expressions))

instance Pretty FunctionCall where
  ppr (FunctionCall postfixExpression expressionElements optClosure) =
    ppr postfixExpression
      <> parens (commasep (map ppr expressionElements))
      <> ppr optClosure

instance Pretty ExpressionElement where
  ppr (ExpressionElement Nothing expression) = ppr expression
  ppr (ExpressionElement (Just ident) expression) = ppr ident <> colon <> space <> ppr expression

instance Pretty Closure where
  ppr (Closure []) = empty
  ppr (Closure statements) = braces (ppr statements)

instance Pretty PrimaryExpression where
  ppr (PrimaryExpression1 idG) = ppr idG
  ppr (PrimaryExpression2 literalExpression) = ppr literalExpression
  ppr (PrimaryExpression3 selfExpression) = ppr selfExpression
  ppr (PrimaryExpression4 superclassExpression) = ppr superclassExpression
  ppr (PrimaryExpression5 closure) = ppr closure
  ppr (PrimaryExpression6 expressionElements) = ppr expressionElements
  ppr PrimaryExpression7 = string "<implicit-member-expression>" -- TODO implicit-member-expression
  ppr PrimaryExpression8 = string "_"

instance Pretty IdG where
  ppr (IdG identifier []) = ppr identifier
  ppr (IdG identifier genericArgs) = ppr identifier <> angles (ppr genericArgs)

instance Pretty BinaryExpression where
  ppr (BinaryExpression1 operator prefixExpression) = ppr operator <> ppr prefixExpression
  ppr (BinaryAssignmentExpression tryOperator prefixExpression) = string "=" <+> ppr tryOperator <+> ppr prefixExpression
  ppr (BinaryExpression3 (optS1, expression) optS2 prefixExpression) =
    ppr optS1 <> ppr expression <> ppr optS2 <> ppr prefixExpression
  ppr (BinaryExpression4 s typ) = ppr s <> ppr typ

instance Pretty LiteralExpression where
  ppr (RegularLiteral lit) =  ppr lit
  ppr (SpecialLiteral special) =  ppr special

instance Pretty Literal where
  ppr (IntegerLiteral n) = integer n
  ppr (FloatingPointLiteral d) = double d
  ppr (StringLiteral s) = dquotes (string s)
  ppr (BooleanLiteral b) = if b then text "true" else text "false"
  ppr NilLiteral = text "nil"

instance Pretty SelfExpression where
  ppr Self1 = string "self"
  ppr (Self2 identifier) = string "self" <> string "." <> string identifier
  ppr (Self3 expressions) = string "self" <> brackets (commasep (map ppr expressions))
  ppr Self4 = string "self" <> string "." <> string "init"

instance Pretty SuperclassExpression where
  ppr (SuperclassExpression) = string "<super>" -- TODO

instance Pretty Type where
  ppr (Type ty) = ppr ty

instance Pretty Statement where
  ppr (ExpressionStatement expression) = ppr expression
  ppr (WhileStatement expression codeBlock) = string "while" <+> ppr expression <+> ppr codeBlock
  ppr (DeclarationStatement declaration) = ppr declaration
  ppr DummyStatement = string "<dummy-statement>"

instance Pretty Declaration where
  ppr (ImportDeclaration attributes optImportKind importPath) = string "import" <> (cat . punctuate dot) (map ppr importPath) -- TODO
  ppr (DeclVariableDeclaration variableDeclaration) = ppr variableDeclaration
  ppr (ConstantDeclaration attributes declarationModifiers patternInitialisers) = string "let" <+> commasep (map ppr patternInitialisers)
  ppr (TypeAlias attributes declaractionModifiers name typ_) = string name <+> string "=" <+> ppr typ_ -- TODO
  ppr DummyDeclaration = string "<dummy-decl>"

instance Pretty ImportPathIdentifier where
  ppr (ImportIdentifier string) = ppr string
  ppr (ImportOperator string) = ppr string

instance Pretty VariableDeclaration where
  ppr (SimpleVariableDeclaration patternInitialisers) = string "var" <+> commasep (map ppr patternInitialisers)

instance Pretty PatternInitializer where
  ppr (PatternInitializer (ExpressionPattern expression) optExpression) = ppr expression <+> ppr optExpression -- FIXME We currently get an Assignment ConstantDeclaration(AssignmentExpression) instead of ConstantDeclaration(IdentifierExpression, Expression)
  ppr (PatternInitializer pattern optExpression) = ppr pattern <+> string "=" <+> string "[[" <+> ppr optExpression <+> string "]]"

instance Pretty Pattern where
  ppr (ExpressionPattern expression) = ppr expression

instance Pretty CodeBlock where
  ppr (CodeBlock statements) = lbrace <> line
    <> ind ((cat . punctuate line) (map ppr statements))
    <> line <> rbrace
