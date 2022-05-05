#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright 2012-2016 Matt Martz
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import os
import re
import csv
import sys
import math
import errno
import signal
import socket
import timeit
import datetime
import platform
import threading
import xml.parsers.expat

try:
    import gzip
    GZIP_BASE = gzip.GzipFile
except ImportError:
    gzip = None
    GZIP_BASE = object

__version__ = '1.0.0'


class FakeShutdownEvent(object):
    """Class to fake a threading.Event.isSet so that users of this module
    are not required to register their own threading.Event()
    """

    @staticmethod
    def isSet():
        "Dummy method to always return false"""
        return False


# Some global variables we use
USER_AGENT = None
SOURCE = None
SHUTDOWN_EVENT = FakeShutdownEvent()
SCHEME = 'http'
DEBUG = False

# Used for bound_interface
SOCKET_SOCKET = socket.socket

# Begin import game to handle Python 2 and Python 3
try:
    import json
except ImportError:
    try:
        import simplejson as json
    except ImportError:
        json = None

try:
    import xml.etree.cElementTree as ET
except ImportError:
    try:
        import xml.etree.ElementTree as ET
    except ImportError:
        from xml.dom import minidom as DOM
        ET = None

try:
    from urllib2 import urlopen, Request, HTTPError, URLError
except ImportError:
    from urllib.request import urlopen, Request, HTTPError, URLError

try:
    from httplib import HTTPConnection
except ImportError:
    from http.client import HTTPConnection

try:
    from httplib import HTTPSConnection
except ImportError:
    try:
        from http.client import HTTPSConnection
    except ImportError:
        HTTPSConnection = None

try:
    from Queue import Queue
except ImportError:
    from queue import Queue

try:
    from urlparse import urlparse
except ImportError:
    from urllib.parse import urlparse

try:
    from urlparse import parse_qs
except ImportError:
    try:
        from urllib.parse import parse_qs
    except ImportError:
        from cgi import parse_qs

try:
    from hashlib import md5
except ImportError:
    from md5 import md5

try:
    from argparse import ArgumentParser as ArgParser
    from argparse import SUPPRESS as ARG_SUPPRESS
    PARSER_TYPE_INT = int
    PARSER_TYPE_STR = str
except ImportError:
    from optparse import OptionParser as ArgParser
    from optparse import SUPPRESS_HELP as ARG_SUPPRESS
    PARSER_TYPE_INT = 'int'
    PARSER_TYPE_STR = 'string'

try:
    from cStringIO import StringIO
    BytesIO = None
except ImportError:
    try:
        from io import StringIO, BytesIO
    except ImportError:
        from StringIO import StringIO
        BytesIO = None

try:
    import builtins
except ImportError:
    def print_(*args, **kwargs):
        """The new-style print function for Python 2.4 and 2.5.

        Taken from https://pypi.python.org/pypi/six/

        Modified to set encoding to UTF-8 if not set when stdout may not be
        a tty such as when piping to head
        """
        fp = kwargs.pop("file", sys.stdout)
        if fp is None:
            return

        def write(data):
            if not isinstance(data, basestring):
                data = str(data)
            # If the file has an encoding, encode unicode with it.
            encoding = fp.encoding or 'UTF-8'  # Diverges for notty
            if (isinstance(fp, file) and
                    isinstance(data, unicode) and
                    encoding is not None):
                errors = getattr(fp, "errors", None)
                if errors is None:
                    errors = "strict"
                data = data.encode(encoding, errors)
            fp.write(data)
        want_unicode = False
        sep = kwargs.pop("sep", None)
        if sep is not None:
            if isinstance(sep, unicode):
                want_unicode = True
            elif not isinstance(sep, str):
                raise TypeError("Set deve ser Nenhum ou um string")
        end = kwargs.pop("end", None)
        if end is not None:
            if isinstance(end, unicode):
                want_unicode = True
            elif not isinstance(end, str):
                raise TypeError("Final deve ser Nenhum ou um string")
        if kwargs:
            raise TypeError("Argumentos de palavra-chave inválidos para imprimir()")
        if not want_unicode:
            for arg in args:
                if isinstance(arg, unicode):
                    want_unicode = True
                    break
        if want_unicode:
            newline = unicode("\n")
            space = unicode(" ")
        else:
            newline = "\n"
            space = " "
        if sep is None:
            sep = space
        if end is None:
            end = newline
        for i, arg in enumerate(args):
            if i:
                write(sep)
            write(arg)
        write(end)
else:
    print_ = getattr(builtins, 'print')
    del builtins

# Exception "constants" to support Python 2 through Python 3
try:
    import ssl
    try:
        CERT_ERROR = (ssl.CertificateError,)
    except AttributeError:
        CERT_ERROR = tuple()

    HTTP_ERRORS = ((HTTPError, URLError, socket.error, ssl.SSLError) +
                   CERT_ERROR)
except ImportError:
    HTTP_ERRORS = (HTTPError, URLError, socket.error)


class SpeedtestException(Exception):
    """Exceção básica para este módulo"""


class SpeedtestHTTPError(SpeedtestException):
    """Exceção HTTP básica para este módulo"""


class SpeedtestConfigError(SpeedtestException):
    """A configuração fornecida é inválida"""


class ConfigRetrievalError(SpeedtestHTTPError):
    """Não foi possível recuperar config.php"""


class ServersRetrievalError(SpeedtestHTTPError):
    """Não foi possível recuperar speedtest-servers.php"""


class InvalidServerIDType(SpeedtestException):
    """O ID do servidor usado para filtragem não era um número inteiro"""


class NoMatchedServers(SpeedtestException):
    """Nenhum servidor correspondeu ao filtrar"""


class SpeedtestMiniConnectFailure(SpeedtestException):
    """Não foi possível conectar ao mini-servidor speedtest fornecido"""


class InvalidSpeedtestMiniServer(SpeedtestException):
    """O servidor fornecido como mini-servidor de teste de velocidade não aparece
    ser um mini-servidor speedtest
    """


class ShareResultsConnectFailure(SpeedtestException):
    """Não foi possível conectar à API speedtest.net para os resultados do POST"""


class ShareResultsSubmitFailure(SpeedtestException):
    """Não foi possível POSTAR os resultados com sucesso para a API speedtest.net após
    conexão
    """


class SpeedtestUploadTimeout(SpeedtestException):
    """Configuração testlength alcançada durante o upload
    Usado para garantir que o upload seja interrompido quando nenhum dado adicional deve ser enviado
    """


class SpeedtestBestServerFailure(SpeedtestException):
    """Não foi possível determinar o melhor servidor"""


class GzipDecodedResponse(GZIP_BASE):
    """Um objeto semelhante a um arquivo para decodificar uma resposta codificada com o gzip
    método, conforme descrito em RFC 1952.

    Largely copied from ``xmlrpclib``/``xmlrpc.client`` and modified
    to work for py2.4-py3
    """
    def __init__(self, response):
        # response doesn't support tell() and read(), required by
        # GzipFile
        if not gzip:
            raise SpeedtestHTTPError('O corpo da resposta HTTP é codificado em gzip, '
                                     'Mas o suporte gzip não está disponível')
        IO = BytesIO or StringIO
        self.io = IO(response.read())
        gzip.GzipFile.__init__(self, mode='rb', fileobj=self.io)

    def close(self):
        try:
            gzip.GzipFile.close(self)
        finally:
            self.io.close()


def bound_socket(*args, **kwargs):
    """Vincular soquete a um endereço IP de origem especificado"""

    sock = SOCKET_SOCKET(*args, **kwargs)
    sock.bind((SOURCE, 0))
    return sock


def distance(origin, destination):
    """Determine a distância entre 2 conjuntos de [lat,lon] em km"""

    lat1, lon1 = origin
    lat2, lon2 = destination
    radius = 6371  # km

    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) * math.sin(dlat / 2) +
         math.cos(math.radians(lat1)) *
         math.cos(math.radians(lat2)) * math.sin(dlon / 2) *
         math.sin(dlon / 2))
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    d = radius * c

    return d


def build_user_agent():
    """Build a Mozilla/5.0 compatible User-Agent string"""

    global USER_AGENT
    if USER_AGENT:
        return USER_AGENT

    ua_tuple = (
        'Mozilla/5.0',
        '(%s; U; %s; en-us)' % (platform.system(), platform.architecture()[0]),
        'Python/%s' % platform.python_version(),
        '(KHTML, like Gecko)',
        'speedtest-cli/%s' % __version__
    )
    USER_AGENT = ' '.join(ua_tuple)
    printer(USER_AGENT, debug=True)
    return USER_AGENT


def build_request(url, data=None, headers=None, bump=''):
    """Crie um objeto de solicitação urllib2

    Esta função adiciona automaticamente um cabeçalho User-Agent a todas as solicitações

    """

    if not USER_AGENT:
        build_user_agent()

    if not headers:
        headers = {}

    if url[0] == ':':
        schemed_url = '%s%s' % (SCHEME, url)
    else:
        schemed_url = url

    if '?' in url:
        delim = '&'
    else:
        delim = '?'

    # WHO YOU GONNA CALL? CACHE BUSTERS!
    final_url = '%s%sx=%s.%s' % (schemed_url, delim,
                                 int(timeit.time.time() * 1000),
                                 bump)

    headers.update({
        'User-Agent': USER_AGENT,
        'Cache-Control': 'no-cache',
    })

    printer('%s %s' % (('GET', 'POST')[bool(data)], final_url),
            debug=True)

    return Request(final_url, data=data, headers=headers)


def catch_request(request):
    """Função auxiliar para capturar exceções comuns encontradas quando
    estabelecendo uma conexão com uma solicitação HTTP/HTTPS

    """

    try:
        uh = urlopen(request)
        return uh, False
    except HTTP_ERRORS:
        e = sys.exc_info()[1]
        return None, e


def get_response_stream(response):
    """Função auxiliar para retornar um leitor Gzip se
    ``Content-Encoding`` é ``gzip`` caso contrário a própria resposta

    """

    try:
        getheader = response.headers.getheader
    except AttributeError:
        getheader = response.getheader

    if getheader('content-encoding') == 'gzip':
        return GzipDecodedResponse(response)

    return response


def get_attributes_by_tag_name(dom, tag_name):
    """Recuperar um atributo de um documento XML e devolvê-lo em um
    formato consistente

    Usado apenas com xml.dom.minidom, que provavelmente só será usado
    com versões python anteriores a 2.5
    """
    elem = dom.getElementsByTagName(tag_name)[0]
    return dict(list(elem.attributes.items()))


def print_dots(current, total, start=False, end=False):
    """Função de retorno de chamada incorporada usada pelas classes Thread para impressão
    status

    """

    if SHUTDOWN_EVENT.isSet():
        return

    sys.stdout.write('.')
    if current + 1 == total and end is True:
        sys.stdout.write('\n')
    sys.stdout.flush()


def do_nothing(*args, **kwargs):
    pass


class HTTPDownloader(threading.Thread):
    """Classe de thread para recuperar um URL"""

    def __init__(self, i, request, start, timeout):
        threading.Thread.__init__(self)
        self.request = request
        self.result = [0]
        self.starttime = start
        self.timeout = timeout
        self.i = i

    def run(self):
        try:
            if (timeit.default_timer() - self.starttime) <= self.timeout:
                f = urlopen(self.request)
                while (not SHUTDOWN_EVENT.isSet() and
                        (timeit.default_timer() - self.starttime) <=
                        self.timeout):
                    self.result.append(len(f.read(10240)))
                    if self.result[-1] == 0:
                        break
                f.close()
        except IOError:
            pass


class HTTPUploaderData(object):
    """Arquivo como objeto para melhorar o corte do upload uma vez que o tempo limite
    foi alcançado
    """

    def __init__(self, length, start, timeout):
        self.length = length
        self.start = start
        self.timeout = timeout

        self._data = None

        self.total = [0]

    def _create_data(self):
        chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        multiplier = int(round(int(self.length) / 36.0))
        IO = BytesIO or StringIO
        self._data = IO(
            ('content1=%s' %
             (chars * multiplier)[0:int(self.length) - 9]
             ).encode()
        )

    @property
    def data(self):
        if not self._data:
            self._create_data()
        return self._data

    def read(self, n=10240):
        if ((timeit.default_timer() - self.start) <= self.timeout and
                not SHUTDOWN_EVENT.isSet()):
            chunk = self.data.read(n)
            self.total.append(len(chunk))
            return chunk
        else:
            raise SpeedtestUploadTimeout

    def __len__(self):
        return self.length


class HTTPUploader(threading.Thread):
    """Classe de thread para colocar uma URL"""

    def __init__(self, i, request, start, size, timeout):
        threading.Thread.__init__(self)
        self.request = request
        self.request.data.start = self.starttime = start
        self.size = size
        self.result = None
        self.timeout = timeout
        self.i = i

    def run(self):
        request = self.request
        try:
            if ((timeit.default_timer() - self.starttime) <= self.timeout and
                    not SHUTDOWN_EVENT.isSet()):
                try:
                    f = urlopen(request)
                except TypeError:
                    # PY24 expects a string or buffer
                    # This also causes issues with Ctrl-C, but we will concede
                    # for the moment that Ctrl-C on PY24 isn't immediate
                    request = build_request(self.request.get_full_url(),
                                            data=request.data.read(self.size))
                    f = urlopen(request)
                f.read(11)
                f.close()
                self.result = sum(self.request.data.total)
            else:
                self.result = 0
        except (IOError, SpeedtestUploadTimeout):
            self.result = sum(self.request.data.total)


class SpeedtestResults(object):
    """Classe para guardar os resultados de um teste de velocidade, incluindo:

    velocidade de download
    Velocidade de upload
    Ping/Latência para testar o servidor
    Dados sobre o servidor em que o teste foi executado

    Além disso, esta classe pode retornar dados de resultado como um dicionário ou CSV,
    bem como enviar um POST dos dados do resultado para a API speedtest.net
    para obter um link de imagem de resultados de compartilhamento.
    """

    def __init__(self, download=0, upload=0, ping=0, server=None):
        self.download = download
        self.upload = upload
        self.ping = ping
        if server is None:
            self.server = {}
        else:
            self.server = server
        self._share = None
        self.timestamp = datetime.datetime.utcnow().isoformat()
        self.bytes_received = 0
        self.bytes_sent = 0

    def __repr__(self):
        return repr(self.dict())

    def share(self):
        """Dados POST para a API speedtest.net para obter um resultado de compartilhamento
        link
        """

        if self._share:
            return self._share

        download = int(round(self.download / 1000.0, 0))
        ping = int(round(self.ping, 0))
        upload = int(round(self.upload / 1000.0, 0))

        # Build the request to send results back to speedtest.net
        # We use a list instead of a dict because the API expects parameters
        # in a certain order
        api_data = [
            'recommendedserverid=%s' % self.server['id'],
            'ping=%s' % ping,
            'screenresolution=',
            'promo=',
            'download=%s' % download,
            'screendpi=',
            'upload=%s' % upload,
            'testmethod=http',
            'hash=%s' % md5(('%s-%s-%s-%s' %
                             (ping, upload, download, '297aae72'))
                            .encode()).hexdigest(),
            'touchscreen=none',
            'startmode=pingselect',
            'accuracy=1',
            'bytesreceived=%s' % self.bytes_received,
            'bytessent=%s' % self.bytes_sent,
            'serverid=%s' % self.server['id'],
        ]

        headers = {'Referer': 'http://c.speedtest.net/flash/speedtest.swf'}
        request = build_request('://www.speedtest.net/api/api.php',
                                data='&'.join(api_data).encode(),
                                headers=headers)
        f, e = catch_request(request)
        if e:
            raise ShareResultsConnectFailure(e)

        response = f.read()
        code = f.code
        f.close()

        if int(code) != 200:
            raise ShareResultsSubmitFailure('Não foi possível enviar resultados para '
                                            'speedtest.net')

        qsargs = parse_qs(response.decode())
        resultid = qsargs.get('resultid')
        if not resultid or len(resultid) != 1:
            raise ShareResultsSubmitFailure('Não foi possível enviar resultados para'
                                            'speedtest.net')

        self._share = 'http://www.speedtest.net/result/%s.png' % resultid[0]

        return self._share

    def dict(self):
        """Dicionário de retorno dois dados resultam"""

        return {
            'download': self.download,
            'upload': self.upload,
            'ping': self.ping,
            'server': self.server,
            'timestamp': self.timestamp
        }

    def csv(self, delimiter=','):
        """Retornar dados em formato CSV"""

        data = self.dict()
        out = StringIO()
        writer = csv.writer(out, delimiter=delimiter, lineterminator='')
        writer.writerow([data['server']['id'], data['server']['sponsor'],
                         data['server']['name'], data['timestamp'],
                         data['server']['d'], data['ping'], data['download'],
                         data['upload']])
        return out.getvalue()

    def json(self, pretty=False):
        """Retornar dados no formato JSON"""

        kwargs = {}
        if pretty:
            kwargs.update({
                'indent': 4,
                'sort_keys': True
            })
        return json.dumps(self.dict(), **kwargs)


class Speedtest(object):
    """Classe para realizar operações de teste padrão do speedtest.net"""

    def __init__(self, config=None):
        self.config = {}
        self.get_config()
        if config is not None:
            self.config.update(config)

        self.servers = {}
        self.closest = []
        self.best = {}

        self.results = SpeedtestResults()

    def get_config(self):
        """Baixe a configuração do speedtest.net e retorne apenas os dados
        Nós estamos interessados ​​em
        """

        headers = {}
        if gzip:
            headers['Accept-Encoding'] = 'gzip'
        request = build_request('://www.speedtest.net/speedtest-config.php',
                                headers=headers)
        uh, e = catch_request(request)
        if e:
            raise ConfigRetrievalError(e)
        configxml = []

        stream = get_response_stream(uh)

        while 1:
            configxml.append(stream.read(10240))
            if len(configxml[-1]) == 0:
                break
        stream.close()
        uh.close()

        if int(uh.code) != 200:
            return None

        printer(''.encode().join(configxml), debug=True)

        try:
            root = ET.fromstring(''.encode().join(configxml))
            server_config = root.find('server-config').attrib
            download = root.find('download').attrib
            upload = root.find('upload').attrib
            # times = root.find('times').attrib
            client = root.find('client').attrib

        except AttributeError:
            root = DOM.parseString(''.join(configxml))
            server_config = get_attributes_by_tag_name(root, 'server-config')
            download = get_attributes_by_tag_name(root, 'download')
            upload = get_attributes_by_tag_name(root, 'upload')
            # times = get_attributes_by_tag_name(root, 'times')
            client = get_attributes_by_tag_name(root, 'client')

        ignore_servers = list(
            map(int, server_config['ignoreids'].split(','))
        )

        ratio = int(upload['ratio'])
        upload_max = int(upload['maxchunkcount'])
        up_sizes = [32768, 65536, 131072, 262144, 524288, 1048576, 7340032]
        sizes = {
            'upload': up_sizes[ratio - 1:],
            'download': [350, 500, 750, 1000, 1500, 2000, 2500,
                         3000, 3500, 4000]
        }

        counts = {
            'upload': int(upload_max * 2 / len(sizes['upload'])),
            'download': int(download['threadsperurl'])
        }

        threads = {
            'upload': int(upload['threads']),
            'download': int(server_config['threadcount']) * 2
        }

        length = {
            'upload': int(upload['testlength']),
            'download': int(download['testlength'])
        }

        self.config.update({
            'client': client,
            'ignore_servers': ignore_servers,
            'sizes': sizes,
            'counts': counts,
            'threads': threads,
            'length': length,
            'upload_max': upload_max
        })

        self.lat_lon = (float(client['lat']), float(client['lon']))

        return self.config

    def get_servers(self, servers=None):
        """Recupere uma lista de servidores speedtest.net, opcionalmente filtrado
        para servidores que correspondem aos especificados no argumento ``servers``
        """
        if servers is None:
            servers = []

        self.servers.clear()

        for i, s in enumerate(servers):
            try:
                servers[i] = int(s)
            except ValueError:
                raise InvalidServerIDType('%s é um tipo de servidor inválido, deve '
                                          'estar dentro' % s)

        urls = [
            '://www.speedtest.net/speedtest-servers-static.php',
            'http://c.speedtest.net/speedtest-servers-static.php',
            '://www.speedtest.net/speedtest-servers.php',
            'http://c.speedtest.net/speedtest-servers.php',
        ]

        headers = {}
        if gzip:
            headers['Accept-Encoding'] = 'gzip'

        errors = []
        for url in urls:
            try:
                request = build_request('%s?threads=%s' %
                                        (url,
                                         self.config['threads']['download']),
                                        headers=headers)
                uh, e = catch_request(request)
                if e:
                    errors.append('%s' % e)
                    raise ServersRetrievalError

                stream = get_response_stream(uh)

                serversxml = []
                while 1:
                    serversxml.append(stream.read(10240))
                    if len(serversxml[-1]) == 0:
                        break

                stream.close()
                uh.close()

                if int(uh.code) != 200:
                    raise ServersRetrievalError

                printer(''.encode().join(serversxml), debug=True)

                try:
                    try:
                        root = ET.fromstring(''.encode().join(serversxml))
                        elements = root.getiterator('server')
                    except AttributeError:
                        root = DOM.parseString(''.join(serversxml))
                        elements = root.getElementsByTagName('server')
                except (SyntaxError, xml.parsers.expat.ExpatError):
                    raise ServersRetrievalError

                for server in elements:
                    try:
                        attrib = server.attrib
                    except AttributeError:
                        attrib = dict(list(server.attributes.items()))

                    if servers and int(attrib.get('id')) not in servers:
                        continue

                    if int(attrib.get('id')) in self.config['ignore_servers']:
                        continue

                    try:
                        d = distance(self.lat_lon,
                                     (float(attrib.get('lat')),
                                      float(attrib.get('lon'))))
                    except:
                        continue

                    attrib['d'] = d

                    try:
                        self.servers[d].append(attrib)
                    except KeyError:
                        self.servers[d] = [attrib]

                printer(''.encode().join(serversxml), debug=True)

                break

            except ServersRetrievalError:
                continue

        if servers and not self.servers:
            raise NoMatchedServers

        return self.servers

    def set_mini_server(self, server):
        """Em vez de consultar uma lista de servidores, defina um link para um
        miniservidor de teste de velocidade
        """

        urlparts = urlparse(server)

        name, ext = os.path.splitext(urlparts[2])
        if ext:
            url = os.path.dirname(server)
        else:
            url = server

        request = build_request(url)
        uh, e = catch_request(request)
        if e:
            raise SpeedtestMiniConnectFailure('Falha ao conectar a %s' %
                                              server)
        else:
            text = uh.read()
            uh.close()

        extension = re.findall('upload_?[Ee]xtension: "([^"]+)"',
                               text.decode())
        if not extension:
            for ext in ['php', 'asp', 'aspx', 'jsp']:
                try:
                    f = urlopen('%s/speedtest/upload.%s' % (url, ext))
                except:
                    pass
                else:
                    data = f.read().strip().decode()
                    if (f.code == 200 and
                            len(data.splitlines()) == 1 and
                            re.match('size=[0-9]', data)):
                        extension = [ext]
                        break
        if not urlparts or not extension:
            raise InvalidSpeedtestMiniServer('Invalid Speedtest Mini Server: '
                                             '%s' % server)

        self.servers = [{
            'sponsor': 'Speedtest Mini',
            'name': urlparts[1],
            'd': 0,
            'url': '%s/speedtest/upload.%s' % (url.rstrip('/'), extension[0]),
            'latency': 0,
            'id': 0
        }]

        return self.servers

    def get_closest_servers(self, limit=5):
        """Limite os servidores aos servidores speedtest.net mais próximos com base em
        distância geográfica
        """

        if not self.servers:
            self.get_servers()

        for d in sorted(self.servers.keys()):
            for s in self.servers[d]:
                self.closest.append(s)
                if len(self.closest) == limit:
                    break
            else:
                continue
            break

        printer(self.closest, debug=True)
        return self.closest

    def get_best_server(self, servers=None):
        """Execute um "ping" speedtest.net para determinar qual speedtest.net
        servidor tem a menor latência
        """

        if not servers:
            if not self.closest:
                servers = self.get_closest_servers()
            servers = self.closest

        results = {}
        for server in servers:
            cum = []
            url = os.path.dirname(server['url'])
            urlparts = urlparse('%s/latency.txt' % url)
            printer('%s %s/latency.txt' % ('GET', url), debug=True)
            for _ in range(0, 3):
                try:
                    if urlparts[0] == 'https':
                        h = HTTPSConnection(urlparts[1])
                    else:
                        h = HTTPConnection(urlparts[1])
                    headers = {'User-Agent': USER_AGENT}
                    start = timeit.default_timer()
                    h.request("GET", urlparts[2], headers=headers)
                    r = h.getresponse()
                    total = (timeit.default_timer() - start)
                except HTTP_ERRORS:
                    e = sys.exc_info()[1]
                    printer('%r' % e, debug=True)
                    cum.append(3600)
                    continue

                text = r.read(9)
                if int(r.status) == 200 and text == 'test=test'.encode():
                    cum.append(total)
                else:
                    cum.append(3600)
                h.close()

            avg = round((sum(cum) / 6) * 1000.0, 3)
            results[avg] = server

        try:
            fastest = sorted(results.keys())[0]
        except IndexError:
            raise SpeedtestBestServerFailure('Não é possível conectar-se a servidores para '
                                             'testa de latência.')
        best = results[fastest]
        best['latency'] = fastest

        self.results.ping = fastest
        self.results.server = best

        self.best.update(best)
        printer(best, debug=True)
        return best

    def download(self, callback=do_nothing):
        """Teste a velocidade de download contra speedtest.net"""

        urls = []
        for size in self.config['sizes']['download']:
            for _ in range(0, self.config['counts']['download']):
                urls.append('%s/random%sx%s.jpg' %
                            (os.path.dirname(self.best['url']), size, size))

        request_count = len(urls)
        requests = []
        for i, url in enumerate(urls):
            requests.append(build_request(url, bump=i))

        def producer(q, requests, request_count):
            for i, request in enumerate(requests):
                thread = HTTPDownloader(i, request, start,
                                        self.config['length']['download'])
                thread.start()
                q.put(thread, True)
                callback(i, request_count, start=True)

        finished = []

        def consumer(q, request_count):
            while len(finished) < request_count:
                thread = q.get(True)
                while thread.isAlive():
                    thread.join(timeout=0.1)
                finished.append(sum(thread.result))
                callback(thread.i, request_count, end=True)

        q = Queue(self.config['threads']['download'])
        prod_thread = threading.Thread(target=producer,
                                       args=(q, requests, request_count))
        cons_thread = threading.Thread(target=consumer,
                                       args=(q, request_count))
        start = timeit.default_timer()
        prod_thread.start()
        cons_thread.start()
        while prod_thread.isAlive():
            prod_thread.join(timeout=0.1)
        while cons_thread.isAlive():
            cons_thread.join(timeout=0.1)

        stop = timeit.default_timer()
        self.results.bytes_received = sum(finished)
        self.results.download = (
            (self.results.bytes_received / (stop - start)) * 8.0
        )
        if self.results.download > 100000:
            self.config['threads']['upload'] = 8
        return self.results.download

    def upload(self, callback=do_nothing):
        """Teste a velocidade de upload contra speedtest.net"""

        sizes = []

        for size in self.config['sizes']['upload']:
            for _ in range(0, self.config['counts']['upload']):
                sizes.append(size)

        # request_count = len(sizes)
        request_count = self.config['upload_max']

        requests = []
        for i, size in enumerate(sizes):
            # We set ``0`` for ``start`` and handle setting the actual
            # ``start`` in ``HTTPUploader`` to get better measurements
            data = HTTPUploaderData(size, 0, self.config['length']['upload'])
            data._create_data()
            requests.append(
                (
                    build_request(self.best['url'], data),
                    size
                )
            )

        def producer(q, requests, request_count):
            for i, request in enumerate(requests[:request_count]):
                thread = HTTPUploader(i, request[0], start, request[1],
                                      self.config['length']['upload'])
                thread.start()
                q.put(thread, True)
                callback(i, request_count, start=True)

        finished = []

        def consumer(q, request_count):
            while len(finished) < request_count:
                thread = q.get(True)
                while thread.isAlive():
                    thread.join(timeout=0.1)
                finished.append(thread.result)
                callback(thread.i, request_count, end=True)

        q = Queue(self.config['threads']['upload'])
        prod_thread = threading.Thread(target=producer,
                                       args=(q, requests, request_count))
        cons_thread = threading.Thread(target=consumer,
                                       args=(q, request_count))
        start = timeit.default_timer()
        prod_thread.start()
        cons_thread.start()
        while prod_thread.isAlive():
            prod_thread.join(timeout=0.1)
        while cons_thread.isAlive():
            cons_thread.join(timeout=0.1)

        stop = timeit.default_timer()
        self.results.bytes_sent = sum(finished)
        self.results.upload = (
            (self.results.bytes_sent / (stop - start)) * 8.0
        )
        return self.results.upload


def ctrl_c(signum, frame):
    """Pegue a sequência de teclas Ctrl-C e defina um SHUTDOWN_EVENT para nosso encadeado
    operações
    """

    SHUTDOWN_EVENT.set()
    print_('\nCancelling...')
    sys.exit(0)


def version():
    """Imprima a versão"""

    print_(__version__)
    sys.exit(0)


def csv_header():
    """Imprima os cabeçalhos CSV"""

    print_('ID do servidor,Patrocinador,Nome do servidor,Timestamp,Distância,Ping,Download,'
           'Carregar')
    sys.exit(0)


def parse_args():
    """Função para lidar com a construção e análise de argumentos de linha de comando"""
    description = (
        'Interface de linha de comando para testar a largura de banda da Internet usando '
        'speedtest.net.\n'
        '------------------------------------------------------------'
        '--------------\n'
        'https://github.com/sivel/speedtest-cli')

    parser = ArgParser(description=description)
    # Give optparse.OptionParser an `add_argument` method for
    # compatibility with argparse.ArgumentParser
    try:
        parser.add_argument = parser.add_option
    except AttributeError:
        pass
    parser.add_argument('--bytes', dest='units', action='store_const',
                        const=('byte', 8), default=('bit', 1),
                        help='Display values in bytes instead of bits. Does '
                             'not affect the image generated by --share, nor '
                             'output from --json or --csv')
    parser.add_argument('--share', action='store_true',
                        help='Generate and provide a URL to the speedtest.net '
                             'share results image')
    parser.add_argument('--simple', action='store_true', default=False,
                        help='Suppress verbose output, only show basic '
                             'information')
    parser.add_argument('--csv', action='store_true', default=False,
                        help='Suppress verbose output, only show basic '
                             'information in CSV format. Speeds listed in '
                             'bit/s and not affected by --bytes')
    parser.add_argument('--csv-delimiter', default=',', type=PARSER_TYPE_STR,
                        help='Single character delimiter to use in CSV '
                             'output. Default ","')
    parser.add_argument('--csv-header', action='store_true', default=False,
                        help='Print CSV headers')
    parser.add_argument('--json', action='store_true', default=False,
                        help='Suppress verbose output, only show basic '
                             'information in JSON format. Speeds listed in '
                             'bit/s and not affected by --bytes')
    parser.add_argument('--list', action='store_true',
                        help='Display a list of speedtest.net servers '
                             'sorted by distance')
    parser.add_argument('--server', help='Specify a server ID to test against',
                        type=PARSER_TYPE_INT)
    parser.add_argument('--mini', help='URL of the Speedtest Mini server')
    parser.add_argument('--source', help='Source IP address to bind to')
    parser.add_argument('--timeout', default=10, type=PARSER_TYPE_INT,
                        help='HTTP timeout in seconds. Default 10')
    parser.add_argument('--secure', action='store_true',
                        help='Use HTTPS instead of HTTP when communicating '
                             'with speedtest.net operated servers')
    parser.add_argument('--version', action='store_true',
                        help='Show the version number and exit')
    parser.add_argument('--debug', action='store_true',
                        help=ARG_SUPPRESS, default=ARG_SUPPRESS)

    options = parser.parse_args()
    if isinstance(options, tuple):
        args = options[0]
    else:
        args = options
    return args


def validate_optional_args(args):
    """Verifique se foi fornecido um argumento que depende de um módulo que pode
    não fazer parte da biblioteca padrão do Python.

    Se tal argumento for fornecido e o módulo não existir, saia
    com um erro informando qual módulo está faltando.
    """
    optional_args = {
        'json': ('json/simplejson python module', json),
        'secure': ('SSL support', HTTPSConnection),
    }

    for arg, info in optional_args.items():
        if getattr(args, arg, False) and info[1] is None:
            raise SystemExit('%s is not installed. --%s is '
                             'unavailable' % (info[0], arg))


def printer(string, quiet=False, debug=False, **kwargs):
    """Função auxiliar para imprimir uma string apenas quando não estiver quieta"""

    if debug and not DEBUG:
        return

    if debug:
        out = '\033[1;30mDEBUG: %s\033[0m' % string
    else:
        out = string

    if not quiet:
        print_(out, **kwargs)


def shell():
    """Execute o teste completo do speedtest.net"""

    global SHUTDOWN_EVENT, SOURCE, SCHEME, DEBUG
    SHUTDOWN_EVENT = threading.Event()

    signal.signal(signal.SIGINT, ctrl_c)

    args = parse_args()

    # Print the version and exit
    if args.version:
        version()

    if args.csv_header:
        csv_header()

    if len(args.csv_delimiter) != 1:
        raise SystemExit('--CSV-delimiter deve ser um único caractere')

    validate_optional_args(args)

    socket.setdefaulttimeout(args.timeout)

    # If specified bind to a specific IP address
    if args.source:
        SOURCE = args.source
        socket.socket = bound_socket

    if args.secure:
        SCHEME = 'https'

    debug = getattr(args, 'debug', False)
    if debug == 'SUPPRESSHELP':
        debug = False
    if debug:
        DEBUG = True

    # Pre-cache the user agent string
    build_user_agent()

    if args.simple or args.csv or args.json:
        quiet = True
    else:
        quiet = False

    # Don't set a callback if we are running quietly
    if quiet or debug:
        callback = do_nothing
    else:
        callback = print_dots

    printer('Recuperando a configuração do speedtest.net...', quiet)
    try:
        speedtest = Speedtest()
    except ConfigRetrievalError:
        printer('Recuperando a configuração do speedtest.net')
        sys.exit(1)

    if args.list:
        try:
            speedtest.get_servers()
        except ServersRetrievalError:
            print_('Não é possível recuperar a lista de servidores de teste de velocidade')
            sys.exit(1)

        for _, servers in sorted(speedtest.servers.items()):
            for server in servers:
                line = ('%(id)5s) %(sponsor)s (%(name)s, %(country)s) '
                        '[%(d)0.2f km]' % server)
                try:
                    print_(line)
                except IOError:
                    e = sys.exc_info()[1]
                    if e.errno != errno.EPIPE:
                        raise
        sys.exit(0)

    # Set a filter of servers to retrieve
    servers = []
    if args.server:
        servers.append(args.server)

    printer('Testando de %(isp)s (%(ip)s)...' % speedtest.config['cliente'],
            quiet)

    if not args.mini:
        printer('Recuperando a lista de servidores speedtest.net...', quiet)
        try:
            speedtest.get_servers(servers)
        except NoMatchedServers:
            print_('Servidores não correspondentes: %s' % args.server)
            sys.exit(1)
        except ServersRetrievalError:
            print_('Não é possível recuperar a lista de servidores de teste de velocidade')
            sys.exit(1)
        except InvalidServerIDType:
            print_('%s É um tipo de servidor inválido, deve ser int' % args.server)
            sys.exit(1)

        printer('Selecionando o melhor servidor com base no ping...', quiet)
        speedtest.get_best_server()
    elif args.mini:
        speedtest.get_best_server(speedtest.set_mini_server(args.mini))

    results = speedtest.results

    printer('Hospedado por %(sponsor)s (%(name)s) [%(d)0.2f km]: '
            '%(latency)s ms' % results.server, quiet)

    printer('Teste a velocidade de download', quiet,
            end=('', '\n')[bool(debug)])
    speedtest.download(callback=callback)
    printer('Download: %0.2f M%s/s' %
            ((results.download / 1000.0 / 1000.0) / args.units[1],
             args.units[0]),
            quiet)

    printer('Teste a velocidade de upload', quiet,
            end=('', '\n')[bool(debug)])
    speedtest.upload(callback=callback)
    printer('Upload: %0.2f M%s/s' %
            ((results.upload / 1000.0 / 1000.0) / args.units[1],
             args.units[0]),
            quiet)

    if args.simple:
        print_('Ping: %s ms\nDownload: %0.2f M%s/s\nUpload: %0.2f M%s/s' %
               (results.ping,
                (results.download / 1000.0 / 1000.0) / args.units[1],
                args.units[0],
                (results.upload / 1000.0 / 1000.0) / args.units[1],
                args.units[0]))
    elif args.csv:
        print_(results.csv(delimiter=args.csv_delimiter))
    elif args.json:
        print_(results.json())

    if args.share:
        printer('Compartilhar resultados: %s' % results.share(), quiet)


def main():
    try:
        shell()
    except KeyboardInterrupt:
        print_('\nCancelamento...')
    except (SpeedtestException, SystemExit):
        e = sys.exc_info()[1]
        if getattr(e, 'Código', 1) != 0:
            raise SystemExit('ERROR: %s' % e)


if __name__ == '__main__':
    main()

# vim:ts=4:sw=4:expandtab
