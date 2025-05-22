local Token = {}
Token.__index = Token

function Token.new(type, value)
  local self = setmetatable({}, Token)
  self.type = type
  self.value = value
  return self
end

function Token:__tostring()
  return string.format("Token(%s, %s)", self.type, tostring(self.value))
end

-- Assuming the Token class and lex function from the lexer code are already defined

-- AST Node Definitions (same as before)
local AST = {}

AST.Program = function(statements)
    return { type = "Program", statements = statements }
end

AST.IfStatement = function(condition, thenBlock, elseifBlocks, elseBlock)
    return { type = "IfStatement", condition = condition, thenBlock = thenBlock, elseifBlocks = elseifBlocks, elseBlock = elseBlock }
end

AST.Block = function(statements)
    return { type = "Block", statements = statements }
end

AST.Assignment = function(target, value)
    return { type = "Assignment", target = target, value = value }
end

AST.BinaryExpression = function(operator, left, right)
    return { type = "BinaryExpression", operator = operator, left = left, right = right }
end

AST.Identifier = function(name)
    return { type = "Identifier", name = name }
end

AST.NumberLiteral = function(value)
    return { type = "NumberLiteral", value = value }
end

AST.StringLiteral = function(value)
    return { type = "StringLiteral", value = value }
end

AST.BooleanLiteral = function(value)
    return { type = "BooleanLiteral", value = value }
end

AST.TableLiteral = function(fields)
    return { type = "TableLiteral", fields = fields }
end

AST.TableAccess = function(base, index)
    return {type = "TableAccess", base = base, index = index}
end

-- Parser
function parse(tokens)
  local i = 1
  function peek()
    return tokens[i]
  end

  function next_token()
      local token = tokens[i]
      i = i + 1
      return token
  end

  function match(expectedType)
      local token = peek()
      if not token then
          return false
      end

      return token.type == expectedType
  end

  function consume(expectedType, errorMessage)
      if not match(expectedType) then
          error("Expected " .. expectedType .. ", got " .. (peek() and peek().type or "EOF") .. (errorMessage and (": " .. errorMessage) or ""))
      end
      return next_token()
  end
  function parse_table()

      local fields = {}
      local implicitKey = 1

      while not match("T_RBRACE") do
          if match("T_IDENTIFIER") and  tokens[i+1] and tokens[i+1].type=="T_OPERATOR" and tokens[i+1].value == "=" then
              -- Key-value pair
              local key = consume("T_IDENTIFIER", "Expected key identifier").value
              consume("T_OPERATOR", "Expected '=' after key")
              local value = parse_expression()
              fields[key] = value --CHANGED LINE
          else
              -- Array-like value
              local value = parse_expression()
              fields[implicitKey] = value --CHANGED LINE
              implicitKey = implicitKey + 1
          end

          if match("T_COMMA") then
              consume("T_COMMA", "Expected comma between table entries")
          elseif not match("T_RBRACE") then
              error("Expected comma or '}' after table entry")
          end
      end

      consume("T_RBRACE", "Expected '}' to end table")
      return AST.TableLiteral(fields)
  end

function parse_primary()
    local token = next_token()
    if token.type == "T_NUMBER" then
        return AST.NumberLiteral(tonumber(token.value))
    elseif token.type == "T_STRING" then
        return AST.StringLiteral(token.value)
    elseif token.type == "T_IDENTIFIER" then
        local identifier = AST.Identifier(token.value)
        if match("T_LSQUARE") then
            next_token() -- Consume the '['
            local index = parse_expression()
            consume("T_RSQUARE", "Expected ']' to close table index")
            return AST.TableAccess(identifier, index)
        else
            return identifier
        end
    elseif token.type == "T_BOOLEAN" then
        return AST.BooleanLiteral(token.value == "true")
    elseif token.type == "T_LPAREN" then
        local expr = parse_expression()
        consume("T_RPAREN", "Expected ')'")
        return expr
    elseif token.type == "T_LBRACE" then
        return parse_table()
    else
        error("Unexpected token in expression: " .. (token and token.type or "EOF"))
    end
end
  function parse_expression()
      local left = parse_primary()
      while match("T_OPERATOR") or match("T_DOT") or match("T_LSQUARE") do
          if match("T_OPERATOR") then
              local operator = next_token().value
              local right = parse_primary()
              left = AST.BinaryExpression(operator, left, right)
           elseif match("T_LSQUARE") then
              next_token() -- Consume the '['
              local index = parse_expression()
              consume("T_RSQUARE", "Expected ']' to close table index")
              left =  AST.TableAccess(left, index)
          elseif match("T_DOT") then
              consume("T_DOT", "Expected '.'")
              local property = consume("T_IDENTIFIER", "Expected identifier after '.'").value
              left = AST.TableAccess(left, property) --Creates inline object
          end
      end
      return left
  end

  function parse_block()
      consume("T_LBRACE", "Expected '{' at start of block")
      local statements = {}

      while not match("T_RBRACE") and not match("T_EOF") do
          local stmt = parse_statement()
          if stmt then
              table.insert(statements, stmt)
          end
      end

      consume("T_RBRACE", "Expected '}' at end of block")
      return AST.Block(statements)
  end

  function parse_if_statement()
      consume("T_IF", "Expected 'if'")
      consume("T_LPAREN", "Expected '(' after 'if'")
      local condition = parse_expression()
      consume("T_RPAREN", "Expected ')' after if condition")
      local thenBlock = parse_block()

      local elseifBlocks = {}
      while match("T_ELSEIF") do
          consume("T_ELSEIF", "Expected 'elseif'")
          consume("T_LPAREN", "Expected '(' after 'elseif'")
          local elseifCondition = parse_expression()
          consume("T_RPAREN", "Expected ')' after elseif condition")
          local elseifBlock = parse_block()
          table.insert(elseifBlocks, {condition = elseifCondition, block = elseifBlock})
      end

      local elseBlock = nil
      if match("T_ELSE") then
          consume("T_ELSE", "Expected 'else'")
          elseBlock = parse_block()
      end

      return AST.IfStatement(condition, thenBlock, elseifBlocks, elseBlock)
  end

  function parse_assignment_statement()
    local target_token = consume("T_IDENTIFIER", "Expected identifier as assignment target")
    consume("T_OPERATOR", "Expected '=' in assignment")
    local target = AST.Identifier(target_token.value)
    local value = parse_expression()
    consume("T_SEMICOLON", "Expected ';' after assignment")
    return AST.Assignment(target, value)
end
function parse_statement()
  local token = peek()
  if not token then return nil end

  if token.type == "T_IF" then
    return parse_if_statement()
  elseif token.type == "T_IDENTIFIER" or token.type == "T_LSQUARE" then
        return parse_assignment_statement()
  elseif token.type == "T_SEMICOLON" then
    next_token()
    return nil
  else
    error("Unexpected token at start of statement: " .. token.type)
  end
end

  function parse_program()
      local statements = {}
      if match("T_LBRACE") then
          -- Parse the entire program as a single block
          local block = parse_block()
          table.insert(statements, block)
      else
          -- Parse a sequence of statements
          while not match("T_EOF") do
              local stmt = parse_statement()
              if stmt then
                  table.insert(statements, stmt)
              end
          end
      end
      return AST.Program(statements)
  end

  return parse_program()
end

-- Example Usage (assuming you have the lexer and Token defined)
local source_code = [[
myTable = {key1 = 1, 2, key2 = "hello", {nested = true}};
x = myTable[key1];
if (x==true) {
  y=5;
}
]]

function lex(source)
  local tokens = {}
  local i = 1

  while i <= #source do
    local char = string.sub(source, i, i)

    if string.match(char, "%s") then -- Whitespace
      i = i + 1
    elseif string.sub(source, i, i + 1) == "if" then
      table.insert(tokens, Token.new("T_IF", "if"))
      i = i + 2
    elseif string.sub(source, i, i + 5) == "elseif" then
      table.insert(tokens, Token.new("T_ELSEIF", "elseif"))
      i = i + 6
    elseif string.sub(source, i, i + 3) == "else" then
      table.insert(tokens, Token.new("T_ELSE", "else"))
      i = i + 4
   --elseif string.sub(source, i, i + 4) == "local" then
   --   table.insert(tokens, Token.new("T_LOCAL", "local"))
   --   i = i + 5
    elseif char == "{" then
      table.insert(tokens, Token.new("T_LBRACE", "{"))
      i = i + 1
    elseif char == "}" then
      table.insert(tokens, Token.new("T_RBRACE", "}"))
      i = i + 1
    elseif char == "(" then
      table.insert(tokens, Token.new("T_LPAREN", "("))
      i = i + 1
    elseif char == ")" then
      table.insert(tokens, Token.new("T_RPAREN", ")"))
      i = i + 1
     elseif char == "[" then
      table.insert(tokens, Token.new("T_LSQUARE", "["))
      i = i + 1
    elseif char == "]" then
      table.insert(tokens, Token.new("T_RSQUARE", "]"))
      i = i + 1
    elseif char == "=" then
      if string.sub(source, i + 1, i + 1) == "=" then
        table.insert(tokens, Token.new("T_OPERATOR", "=="))
        i = i + 2
      else
        table.insert(tokens, Token.new("T_OPERATOR", "="))
        i = i + 1
      end
    elseif char == "+" then
      table.insert(tokens, Token.new("T_OPERATOR", "+"))
      i = i + 1
    elseif char == "-" then
      table.insert(tokens, Token.new("T_OPERATOR", "-"))
      i = i + 1
    elseif char == "*" then
      table.insert(tokens, Token.new("T_OPERATOR", "*"))
      i = i + 1
    elseif char == "/" then
      table.insert(tokens, Token.new("T_OPERATOR", "/"))
      i = i + 1
    elseif char == ";" then
      table.insert(tokens, Token.new("T_SEMICOLON", ";"))
      i = i + 1
    elseif char == "," then
      table.insert(tokens, Token.new("T_COMMA", ","))
      i = i + 1
    elseif char == "." then
      table.insert(tokens, Token.new("T_DOT", "."))
      i = i + 1
    elseif string.match(char, "%a") then -- Identifiers
      local identifier = char
      local j = i + 1
      while j <= #source and string.match(string.sub(source, j, j), "%w") do
        identifier = identifier .. string.sub(source, j, j)
        j = j + 1
      end
      table.insert(tokens, Token.new("T_IDENTIFIER", identifier))
      i = j
    elseif string.match(char, "%d") then -- Numbers
      local number = char
      local j = i + 1
      while j <= #source and string.match(string.sub(source, j, j), "%d") do
        number = number .. string.sub(source, j, j)
        j = j + 1
      end
      table.insert(tokens, Token.new("T_NUMBER", number))
      i = j
    elseif char == '"' or char == "'" then -- Strings
      local string_value = ""
      local j = i + 1
      local quote_char = char
      while j <= #source and string.sub(source, j, j) ~= quote_char do
        string_value = string_value .. string.sub(source, j, j)
        j = j + 1
      end
      if j <= #source and string.sub(source, j, j) == quote_char then
        table.insert(tokens, Token.new("T_STRING", string_value))
        i = j + 1
      else
        error("Unterminated string")
      end
    else
      error("Unexpected character: " .. char)
    end
  end

  table.insert(tokens, Token.new("T_EOF", nil))
  return tokens
end
function print_ast(node, indent)
    indent = indent or ""
    if not node then return end
    print(indent .. "Type: " .. node.type)
    for k, v in pairs(node) do
        if k == "elseifBlocks" and type(v) == "table" then
            print(indent .. "  elseifBlocks:")
            for i, elseifBlock in ipairs(v) do
                print(indent .. "    [" .. i .. "]:")
                print(indent .. "      Condition:")
                print_ast(elseifBlock.condition, indent .. "        ")
                print(indent .. "      Block:")
                print_ast(elseifBlock.block, indent .. "        ")
            end
             elseif k == "fields" and type(v) == "table" then
                print(indent .. "  fields:")
                for key, value in pairs(v) do
                    print(indent .. "    " .. tostring(key) .. ":")
                    print_ast(value, indent .. "      ")
                end
            elseif type(v) == "table" and v.type then
                print(indent .. "  " .. k .. ":")
                print_ast(v, indent .. "    ")
            elseif type(v) == "table" then
                print(indent .. "  " .. k .. ":")
                for i, item in ipairs(v) do
                    if type(item) == "table" and item.type then
                        print(indent .. "    [" .. i .. "]:")
                        print_ast(item, indent .. "      ")
                    else
                        print(indent .. "    [" .. i .. "]: " .. tostring(item))
                    end
                end
            else
                print(indent .. "  " .. k .. ": " .. tostring(v))
            end
        end
    end
local tokens = lex(source_code)
local ast = parse(tokens)

-- Print the AST (for debugging) - Replace with your AST printing function

print_ast(ast)