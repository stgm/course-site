class GradingFormulaEvaluator
  Token = Struct.new(:type, :value)

  PATTERNS = [
    [ :number, /\d+(?:\.\d+)?/     ],
    [ :lte,    /<=/                 ],
    [ :gte,    />=/                 ],
    [ :eq,     /==/                 ],
    [ :neq,    /!=/                 ],
    [ :and,    /&&/                 ],
    [ :or,     /\|\|/              ],
    [ :lt,     /</                  ],
    [ :gt,     />/                  ],
    [ :floor,  /\.floor\b/          ],
    [ :ceil,   /\.ceil\b/           ],
    [ :round,  /\.round(?:\(\d+\))?/],
    [ :plus,   /\+/                 ],
    [ :minus,  /-/                  ],
    [ :star,   /\*/                 ],
    [ :slash,  /\//                 ],
    [ :lparen, /\(/                 ],
    [ :rparen, /\)/                 ],
    [ :name,   /[a-z_]\w*/          ],
    [ :space,  /\s+/                ],
  ].freeze

  MAX_PARENS = 10

  # Returns a Float rounded to 1 decimal, or nil on any error.
  def self.evaluate(formula, variables = {})
    return nil if formula.blank?
    return nil if formula.count("(") > MAX_PARENS
    tokens = tokenize(formula).reject { |t| t.type == :space }
    Parser.new(tokens, variables).parse.to_f.round(1)
  rescue
    nil
  end

  def self.tokenize(formula)
    pos = 0
    tokens = []
    while pos < formula.length
      matched = PATTERNS.any? do |type, pattern|
        if (m = formula[pos..].match(/\A(#{pattern.source})/))
          tokens << Token.new(type, m[1])
          pos += m[1].length
          true
        end
      end
      raise "unexpected character '#{formula[pos]}' at position #{pos}" unless matched
    end
    tokens
  end

  class Parser
    def initialize(tokens, variables)
      @tokens = tokens
      @pos    = 0
      @vars   = variables
    end

    def parse
      val = parse_or
      raise "unexpected token: #{current.inspect}" if @pos < @tokens.length
      val
    end

    private

    def current = @tokens[@pos]
    def match?(*types) = current && types.include?(current.type)

    def consume
      tok = @tokens[@pos]
      @pos += 1
      tok
    end

    # logical — uses Ruby value semantics so `(x >= 9) && x || 0` works
    def parse_or
      left = parse_and
      while match?(:or)
        consume
        right = parse_and
        left = left || right
      end
      left
    end

    def parse_and
      left = parse_comparison
      while match?(:and)
        consume
        right = parse_comparison
        left = left && right
      end
      left
    end

    def parse_comparison
      left = parse_additive
      if match?(:lt, :gt, :lte, :gte, :eq, :neq)
        op = consume.type
        right = parse_additive
        left = case op
               when :lt  then left < right
               when :gt  then left > right
               when :lte then left <= right
               when :gte then left >= right
               when :eq  then left == right
               when :neq then left != right
               end
      end
      left
    end

    def parse_additive
      left = parse_multiplicative
      while match?(:plus, :minus)
        op = consume.type
        right = parse_multiplicative
        left = op == :plus ? left + right : left - right
      end
      left
    end

    def parse_multiplicative
      left = parse_unary
      while match?(:star, :slash)
        op = consume.type
        right = parse_unary
        left = op == :star ? left * right : left / right
      end
      left
    end

    def parse_unary
      if match?(:minus)
        consume
        return -parse_unary
      end
      parse_postfix
    end

    def parse_postfix
      val = parse_primary
      while match?(:floor, :ceil, :round)
        op = consume.type
        val = case op
              when :floor then val.to_f.floor.to_f
              when :ceil  then val.to_f.ceil.to_f
              when :round then val  # precision applied uniformly in evaluate
              end
      end
      val
    end

    def parse_primary
      tok = current
      case tok&.type
      when :number
        consume
        tok.value.include?(".") ? tok.value.to_f : tok.value.to_i.to_f
      when :name
        consume
        key_sym = tok.value.to_sym
        if @vars.key?(key_sym)
          raise "nil variable: #{tok.value}" if @vars[key_sym].nil?
          @vars[key_sym].to_f
        elsif @vars.key?(tok.value)
          raise "nil variable: #{tok.value}" if @vars[tok.value].nil?
          @vars[tok.value].to_f
        else
          raise "unknown variable: #{tok.value}"
        end
      when :lparen
        consume
        val = parse_or
        raise "expected ')'" unless match?(:rparen)
        consume
        val
      else
        raise "unexpected token: #{tok.inspect}"
      end
    end
  end
end
