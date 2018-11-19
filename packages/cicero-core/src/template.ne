# Dynamically Generated
@{%
    function compact(v) {
        if (Array.isArray(v)) {
            return v.reduce((a, v) => (v === null || v === undefined || (v && v.length === 0) ) ? a : (a.push(v), a), []);
        } else {
            return v;
        }
    }

    function flatten(v) {
        let r;
        if (Array.isArray(v)) {
            r = v.reduce((a,v) => (a.push(...((v && Array.isArray(v)) ? flatten(v) : [v])), a), []);
        } else {
            r = v;
        }
        r = compact(r);
        return r;
        }
%}

<% for r in textRules %>
{{ r.prefix }} -> <% for s in r.symbols -%>{{ s }} <% endfor %>
{% ([ {{ r.symbols }} ]) => {
    return {
        <% if r.class %>$class: "{{ r.class }}",<% endif %>
        <% if r.identifier %>{{ r.identifier }},<% endif %>
        <%- for p in r.properties %>
        {{ p }}
        <%- endfor %>
    };
}
%}
<% endfor %>

<% for r in modelRules %>
{{ r.prefix }} -> <% for s in r.symbols -%>{{ s }} <% endfor %>
<% if r.properties %>
{% ( data ) => {
    return {
        $class: "{{ r.class }}",
        <%- for p in r.properties %>
        {{ p }}
        <%- endfor %>
    };
}
%}
<% endif %>
<% endfor %>

# Basic types
NUMBER -> [0-9] 
{% (d) => {return parseInt(d[0]);}%}

DOUBLE_NUMBER -> NUMBER NUMBER
{% (d) => {return '' + d[0] + d[1]}%}

MONTH -> DOUBLE_NUMBER
DAY -> DOUBLE_NUMBER
YEAR -> DOUBLE_NUMBER DOUBLE_NUMBER
{% (d) => {return '' + d[0] + d[1]}%}

DATE -> MONTH "/" DAY "/" YEAR
{% (d) => {return '' + d[4] + '-' + d[0] + '-' + d[2]}%}

Word -> [\S]:*
{% (d) => {return d[0].join('');}%}

BRACKET_PHRASE -> "[" Word (__ Word):* "]" {% ((d) => {return d[1] + ' ' + flatten(d[2]).join(" ");}) %}

String -> dqstring {% id %}
Double -> decimal {% id %}
Integer -> int {% id %}
Long -> int {% id %}
Boolean -> "true" {% id %} | "false" {% id %}
DateTime -> DATE  {% id %}

# https://github.com/kach/nearley/blob/master/builtin/number.ne
unsigned_int -> [0-9]:+ {%
    function(d) {
        return parseInt(d[0].join(""));
    }
%}

int -> ("-"|"+"):? [0-9]:+ {%
    function(d) {
        if (d[0]) {
            return parseInt(d[0][0]+d[1].join(""));
        } else {
            return parseInt(d[1].join(""));
        }
    }
%}

unsigned_decimal -> [0-9]:+ ("." [0-9]:+):? {%
    function(d) {
        return parseFloat(
            d[0].join("") +
            (d[1] ? "."+d[1][1].join("") : "")
        );
    }
%}

decimal -> "-":? [0-9]:+ ("." [0-9]:+):? {%
    function(d) {
        return parseFloat(
            (d[0] || "") +
            d[1].join("") +
            (d[2] ? "."+d[2][1].join("") : "")
        );
    }
%}

percentage -> decimal "%" {%
    function(d) {
        return d[0]/100;
    }
%}

jsonfloat -> "-":? [0-9]:+ ("." [0-9]:+):? ([eE] [+-]:? [0-9]:+):? {%
    function(d) {
        return parseFloat(
            (d[0] || "") +
            d[1].join("") +
            (d[2] ? "."+d[2][1].join("") : "") +
            (d[3] ? "e" + (d[3][1] || "+") + d[3][2].join("") : "")
        );
    }
%}

# From https://github.com/kach/nearley/blob/master/builtin/string.ne
# Matches various kinds of string literals

# Double-quoted string
dqstring -> "\"" dstrchar:* "\"" {% function(d) {return d[1].join(""); } %}
sqstring -> "'"  sstrchar:* "'"  {% function(d) {return d[1].join(""); } %}
btstring -> "`"  [^`]:*    "`"  {% function(d) {return d[1].join(""); } %}

dstrchar -> [^\\"\n] {% id %}
    | "\\" strescape {%
    function(d) {
        return JSON.parse("\""+d.join("")+"\"");
    }
%}

sstrchar -> [^\\'\n] {% id %}
    | "\\" strescape
        {% function(d) { return JSON.parse("\""+d.join("")+"\""); } %}
    | "\\'"
        {% function(d) {return "'"; } %}

strescape -> ["\\/bfnrt] {% id %}
    | "u" [a-fA-F0-9] [a-fA-F0-9] [a-fA-F0-9] [a-fA-F0-9] {%
    function(d) {
        return d.join("");
    }
%}

# From https://github.com/kach/nearley/blob/master/builtin/whitespace.ne
# Whitespace: `_` is optional, `__` is mandatory.
_  -> wschar:* {% function(d) {return null;} %}
__ -> wschar:+ {% function(d) {return null;} %}

wschar -> [ \t\n\v\f] {% id %}