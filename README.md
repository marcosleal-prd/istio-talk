<h1 align="center">Monitoramento e Solução de Problemas com Istio 👋</h1>
<p>
<a href="https://www.linkedin.com/in/marcosleal-prd/">
 <img src="https://img.shields.io/badge/linkedin-%230077B5.svg?&style=for-the-badge&logo=linkedin&logoColor=white" />
</a>&nbsp;&nbsp;
<a href="https://twitter.com/marcosleal_prd">
  <img src="https://img.shields.io/badge/twitter-%231DA1F2.svg?&style=for-the-badge&logo=twitter&logoColor=white" />
</a>&nbsp;&nbsp;
<a href="https://www.instagram.com/marcosleal.prd/">
  <img src="https://img.shields.io/badge/instagram-%23E4405F.svg?&style=for-the-badge&logo=instagram&logoColor=white" />
</a>&nbsp;&nbsp;
<a href="https://medium.com/@marcosleal.prd">
  <img src="https://img.shields.io/badge/medium-%2312100E.svg?&style=for-the-badge&logo=medium&logoColor=white" />
</a>
</p>

> Arquivos utilizados na **JS+ TechTalks #4 - Microsserviços - Monitoramento e Solução de Problemas com Istio (Service Mesh)**

## Sobre

Microsserviços são complexos e muito difíceis, não é uma mera afirmativa. Todo desenvolvedor chega a essa conclusão quando coloca o primeiro projeto em produção usando a arquitetura.

O mais legal de tudo é que grandes empresas (com recursos) também chegaram à essa mesma conclusão, e para resolver os principais problemas encontrados nesses cenários elas criaram soluções open source para ajudar a comunidade, como a Netflix por exemplo.

Apesar de microsserviços serem realmente difíceis, a disseminação do conhecimento sobre esse tema evoluiu bastante. Escolha a linguagem e procure por soluções de circuit breaking no principal repositório de pacotes do idioma para ver o que encontra. O grande problema dessas soluções é que devem ser implementadas em todos os artefatos do sistema, agora imagine em uma arquitetura com pouco mais de 50 microsserviços, isso pode ser complicado :(

Com esse cenário em mente, ao invés de tentar resolver os problemas em nível de aplicação, vamos aplicar essas estas soluções à infraestrutura.

E é finalmente nesse momento que vamos conhecer o Service Mash Istio. Ele foi criado para resolver situações como as descritas acima, utilizando o Envoy como implementação de sidecar, ele permite que você aplique soluções distribuídas em todos os microsserviços sem adicionar nenhuma linha de configuração às suas aplicações.

O Istio resolve de forma global problemas como tracing, circuit breaking, roteamento, injeção, autenticação, etc. E nessa talk vamos entender como o Istio funciona e principalmente, como podemos utilizá-lo para monitorar e solucionar problemas de forma escalável.

## Requisitos

Para que sua experiência com a reprodução da demo seja o mais simples possível, você precisará ter:

- Um editor, eu utilizo o [VSCode](https://code.visualstudio.com/) (para visualizar e testar alterações);
- [Docker](https://www.docker.com/) (utilizado para subir o cluster [Kubernetes](http://kubernetes.io/) local);
- [Kind](https://kind.sigs.k8s.io/) (para criação de cluster local);
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (para aplicar as receitas do Istio);
- [k9s](https://k9scli.io/) (gerenciamento de cluster - opcional)

## Comandos

Todos os comandos estão presentes no arquivo [`COMMANDS.md`](COMMANDS.md). Siga com atenção :wink:

## Autor

👤 **Marcos V. Leal**

* Website: https://juntossomosmais.com.br
* Twitter: [@marcosleal\_prd](https://twitter.com/marcosleal\_prd)
* Github: [@marcosleal-prd](https://github.com/marcosleal-prd)
* LinkedIn: [@marcosleal-prd](https://linkedin.com/in/marcosleal-prd)
* Speaker Deck: [@marcosleal_prd]([https://speakerdeck.com/marcosleal_prd/) (slides)

## Seu apoio

Dê uma ⭐️ se esse projeto ajudou você!

***
_Este README foi gerado com ❤️ por [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_