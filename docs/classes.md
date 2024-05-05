# 📜 Classes #

O modulo de classes do **DREAMCORE** cede um otimo suporte a
**POO** (Programação Orientada a Objetos), dando suporte a private e public por exemplo.

---

## Importando classes para o seus projeto ##

Para usar o modulo de class do **DREAMCORE** é necessario o dreamcore iniciado e o modulo importado para o seu projeto.

Para isso usaremos o seguinte codigo:

```lua
local modules = {'namespacer'} 

for k,v in ipairs(modules) do
    loadstring(exports.dreamcore:import(v)) ();
end

class = dreamcore.class
```

com o codigo acima você já está pronto para trabalhar com classes em seu projeto.

## Iniciando uma Class ##

Para criar uma nova class é necessario a função:

```lua
--- @return table
class:create(string typef, table parent, string nspacer)
```

aqui vai um exemplo de inicialização de uma classe chamada **helloworld**, que recebe uma função publica nomeada de 'say' que faz a saida da string [hello world] e retorna true no fim:

```lua
--- @return table
helloworld = class:create('helloWorld')

--- @return boolean
function helloworld.public:say()
    print('hello world')
    return true
end

helloworld.public:say() -- saida: 'hello world'
```

## Guardando variáveis privadas ##

após criarmos uma função publica usando a chave 'public' da nossa classe **helloworld**, agora nesta seção iremos ver como usar a chave 'private' da nossa classe para guardar o que a função 'say' deve retornar. Para isso usaremos o codigo abaixo:

```lua
--- @return table
helloworld = class:create('helloWorld')

-- coloca o valor ['hello world'] na chave ['private.output'] da nossa classe
helloworld.private.output = 'hello world'

--- @return boolean
function helloworld.public:say()
    -- para puxarmos os valor da chave private.output bastar usar [helloworld.private.output]
    print(helloworld.private.output)
    return true
end

helloworld.public:say() -- saida: 'hello world'
```

## Setter's & Getter's ##

Agora imagine que você deseja que a variável output seja modificável, é ai que entra os (Setter's & Getter's), função chamadas para quando precisamos mudar ou desejamos pegar o valor de uma variavel privada.

Neste exemplo iremos criar duas funções publicas, a 'setOutput' para mudar o valor da nossa variavel e a função 'getOutput' para puxarmos o valor da variavel output.

```lua
--- @return table
helloworld = class:create('helloWorld')

-- coloca o valor ['hello world'] na chave ['private.output'] da nossa classe
helloworld.private.output = 'hello world'


--- @return boolean
function helloworld.public:setOutput(newValue)
    if (not newValue) then return false end

    -- muda o valor da variavel output para o valor [newValue]
    helloworld.private.output = tostring(newValue)
    return true
end

--- @return string
function helloworld.public:getOutput()
    -- retorna o valor atual de output
    return helloworld.private.output
end

--- @return boolean
function helloworld.public:say()
    -- para puxarmos os valor da chave private.output bastar usar [helloworld.private.output]
    print(helloworld.public:getOutput()) -- chama a função getOutput()
    return true
end

helloworld.public:say() -- saida: 'hello world'

helloworld.public:setOutput('dreamcore is amazing') -- 
helloworld.public:say() -- sainda: 'dreamcore is amazing'
```

***

<center><span style='color: gray;'>Documentando por @prxyu</span></center>
<center><span style='color: gray;'>DreamCore</span></center>
