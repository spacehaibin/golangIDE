FROM golang:1.15-alpine

RUN apk add --no-cache \
	bash \
	gcc \
	vim \
	git \
	curl \
	ctags \
	nodejs-current \
	npm \
	tzdata \
	htop \
	protoc \
	make \
	musl-dev

SHELL ["/bin/bash", "-c"]

ENV GOCACHE /tmp
ENV HOME /home/ide
ENV GOPATH $HOME/go
ENV PATH $GOPATH/bin:$PATH

# Create user/group : ide/develop
RUN addgroup develop && adduser -D -h $HOME -s /bin/bash -G develop ide
USER ide:develop
WORKDIR $HOME

# Prepare for the vim 8 plugin
RUN mkdir -m 0755 -p ~/.vim

# Install molokai colorscheme
WORKDIR /tmp
RUN git clone https://github.com/tomasr/molokai.git && \ 
	cd molokai/ && mv colors ~/.vim && cd .. && rm -rf molokai/

# Install Dockerfile plugin
WORKDIR /tmp
RUN git clone https://github.com/ekalinin/Dockerfile.vim.git && \
	cd Dockerfile.vim && make install && cd .. &&  rm -rf Dockerfile.vim

# Install lightline
RUN git clone https://github.com/itchyny/lightline.vim ~/.vim/pack/plugins/start/lightline && \
	vim +"helptags ~/.vim/pack/plugins/start/lightline/doc" +qall

# Install nerdtree
RUN git clone https://github.com/preservim/nerdtree.git ~/.vim/pack/vendor/start/nerdtree && \ 
	vim +"helptags ~/.vim/pack/vendor/start/nerdtree/doc" +qall
#RUN vim -u NONE -c "helptags ~/.vim/pack/vendor/start/nerdtree/doc" -c q

# Install tagbar 
RUN git clone https://github.com/majutsushi/tagbar.git ~/.vim/pack/plugins/start/tagbar && \
	vim +"helptags ~/.vim/pack/plugins/start/tagbar/doc" +qall

# Setup vim-go
RUN git clone https://github.com/fatih/vim-go.git ~/.vim/pack/plugins/start/vim-go
# Perform vim-go :GoInstallBinaries command
# v1 vim +GoInstallBinaries +qall
# v2 vim +'silent :GoInstallBinaries' +qall
# v3 bash -c 'echo | echo | vim +GoInstallBinaries +qall &>/dev/null'
# see .vim/pack/plugins/start/vim-go/plugin/go.vim for more detail
ENV GO111MODULE=on
RUN go get github.com/klauspost/asmfmt/cmd/asmfmt@master
RUN go get github.com/go-delve/delve/cmd/dlv@master
RUN go get github.com/kisielk/errcheck@master
RUN go get github.com/davidrjenni/reftools/cmd/fillstruct@master
RUN go get github.com/rogpeppe/godef@master
RUN go get golang.org/x/tools/cmd/goimports@master
RUN go get golang.org/x/lint/golint@master
RUN go get golang.org/x/tools/gopls@latest

RUN go get github.com/golangci/golangci-lint/cmd/golangci-lint@master
# refer to https://golangci-lint.run/usage/install/
# RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.30.0

RUN go get github.com/fatih/gomodifytags@master
RUN go get golang.org/x/tools/cmd/gorename@master
RUN go get github.com/jstemmer/gotags@master
RUN go get golang.org/x/tools/cmd/guru@master
RUN go get github.com/josharian/impl@master
RUN go get honnef.co/go/tools/cmd/keyify@master
RUN go get github.com/fatih/motion@master
RUN go get github.com/koron/iferr@master

# Go plugin for the protocol compiler:protoc-gen-go
RUN go get github.com/golang/protobuf/protoc-gen-go

# Install coc.nvim
RUN mkdir -m 0755 -p ~/.vim/pack/coc/start
WORKDIR /tmp
RUN curl -O -L https://github.com/neoclide/coc.nvim/archive/v0.0.78.tar.gz
RUN tar xvf v0.0.78.tar.gz && \
	mv coc.nvim-0.0.78/  ~/.vim/pack/coc/start && \
	rm -rf  v0.0.78.tar.gz

# Prepare coc.nvim ~ extensions
RUN mkdir -m 0755 -p ~/.config/coc/extensions 
WORKDIR /tmp
RUN touch package.json && \
 	echo '{"dependencies":{}}' >> package.json && \
	mv package.json ~/.config/coc/extensions

# Install COC extension 
WORKDIR  ~/.config/coc/extensions
RUN cd ~/.config/coc/extensions && npm install coc-go coc-json coc-snippets --global-style \
        --ignore-scripts --no-bin-links --no-package-lock --only=prod

# Copy the .vimrc file and coc-settings.json
COPY --chown=ide:develop coc-settings.json $HOME/.vim/
COPY --chown=ide:develop vim-config/vimrc $HOME/.vimrc

# create the empty proj directory for volume mount
RUN mkdir -p $HOME/proj

# Setup the shell environement
RUN touch $HOME/.bash_profile && \
	echo 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi' >> $HOME/.bash_profile 
RUN touch $HOME/.bashrc && \
	echo >> $HOME/.bashrc && \
	echo 'export GOCACHE=/tmp' >> $HOME/.bashrc && \
	echo 'export GO111MODULE=on' >>  $HOME/.bashrc && \
	echo 'export GOPATH=$HOME/go' >> $HOME/.bashrc && \
 	echo 'export LANG=en_US.UTF-8' >> $HOME/.bashrc  && \
	echo 'export PATH=$GOPATH/bin:/usr/local/go/bin:$PATH' >> $HOME/.bashrc  && \
	echo 'alias vi=vim' >> $HOME/.bashrc && \ 
	echo "export PS1='\u@\h:\w $ '" >> $HOME/.bashrc

# Cleaning  
# RUN go clean -cache && go clean -testcache
USER root
RUN apk del make musl-dev

# Final command
USER ide:develop
WORKDIR $HOME
CMD ["/bin/bash"]
