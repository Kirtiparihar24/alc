(function (f, a, c, g, e) {
    var h = {};
    function b(i) {
        return c.translate(i) || i
    }
    function d(i) {
        i.html('<div class="plupload_wrapper"><div class="ui-widget-content plupload_container"><div class="plupload"><div class="ui-state-default ui-widget-header plupload_header"><div class="plupload_header_content plupload_hidden"></div></div><div class="plupload_content p5 border_gray mt5"><table class="plupload_filelist"><tr class="ui-widget-header plupload_filelist_header"><td class="plupload_cell plupload_file_name" width="65%">' + b("Filename") + '</td><td class="plupload_cell plupload_file_extension" width="10%">' + b("Extension") + '</td><td class="plupload_cell plupload_file_status" width="10%">' + b("Status") + '</td><td class="plupload_cell plupload_file_size" width="10%">' + b("Size") + '</td><td class="plupload_cell plupload_file_action" width="5%">&nbsp;</td></tr></table><div class="plupload_scroll"><table class="plupload_filelist_content"></table></div><table class="plupload_filelist"><tr class="ui-widget-header ui-widget-content plupload_filelist_footer plupload_cell"><td class="plupload_cell plupload_file_name" width="65%"><div class="plupload_buttons pt5"><!-- Visible --><a class="plupload_button plupload_add" style="width:80px;padding:4px">' + b("Add Files") + '</a>&nbsp;<a class="plupload_button plupload_start mr5" style="width:105px;padding:4px">' + b("Upload") + '<a class="plupload_button plupload_reset" style="width:105px;padding:4px">'+ b('Reset') + '</a>&nbsp;' +'</a>&nbsp;<a class="plupload_button plupload_stop plupload_hidden" style="width:100px;padding:4px">' + b("Stop") + '</a>&nbsp;<a class="plupload_button plupload_cancel" style="width:80px;padding:4px">' + b("Cancel") + '</a>&nbsp;</div><div class="plupload_started plupload_hidden"><!-- Hidden --></td><td  width="10%">&nbsp;</td><td class="plupload_file_status" width="10%"><span class="plupload_total_status" width="5%">0%</span></td><td class="plupload_file_size"><span class="plupload_total_file_size" width="6%">0 kb</span></td><td class="plupload_file_action" width="5%"></td></tr><tr class="plupload_cell"><td colspan="5"><table><tr><td><div class="plupload_cell plupload_upload_status pt10 pr5">Uploaded 203/812 files</div></div></td><td><div class="plupload_progress plupload_right  mt5 mr5"><div aria-valuenow="4" aria-valuemax="10" aria-valuemin="0" role="progressbar" class="plupload_progress_container ui-progressbar ui-widget ui-widget-content ui-corner-all"></div></td><td><div class="plupload_clearer">&nbsp;</div></div><div class="plupload_file_queue">Queued files</div></td></tr></table></td></tr></table></div></div></div><input class="plupload_count" value="0" type="hidden"></div>')
    }
    g.widget("ui.plupload", {
        contents_bak: "",
        runtime: null,
        options: {
            browse_button_hover: "ui-state-hover",
            browse_button_active: "ui-state-active",
            dragdrop: true,
            multiple_queues: true,
            buttons: {
                browse: true,
                start: true,
                stop: true,
                reset: true,
                cancel: true
            },
            autostart: false,
            sortable: false,
            rename: false,
            max_file_count: 0
        },
        FILE_COUNT_ERROR: -9001,
        _create: function () {
            var i = this,
                k, j;
            k = this.element.attr("id");
            if (!k) {
                k = c.guid();
                this.element.attr("id", k)
            }
            this.id = k;
            this.contents_bak = this.element.html();
            d(this.element);
            this.container = g(".plupload_container", this.element).attr("id", k + "_container");
            this.filelist = g(".plupload_filelist_content", this.container).attr({
                id: k + "_filelist",
                unselectable: "on"
            });
            this.browse_button = g(".plupload_add", this.container).attr("id", k + "_browse");
            this.start_button = g(".plupload_start", this.container).attr("id", k + "_start");
            this.stop_button = g(".plupload_stop", this.container).attr("id", k + "_stop");
            this.reset_button = g('.plupload_reset', this.container).attr('id', k + '_reset');
            this.cancel_button = g(".plupload_cancel", this.container).attr("id", k + "_cancel");
            if (g.ui.button) {
                this.browse_button.button({
                    icons: {
                        primary: "ui-icon-circle-plus fl mr5"
                    }
                });
                this.start_button.button({
                    icons: {
                        primary: "ui-icon-circle-arrow-e fl mr5"
                    },
                    disabled: true
                });
                this.stop_button.button({
                    icons: {
                        primary: "ui-icon-circle-close fl mr5"
                    }
                });
                this.reset_button.button({
                    icons: {
                        primary: 'ui-icon-circle-close fl mr5'
                    },
                    disabled: true
                });
                this.cancel_button.button({
                    icons: {
                        primary: 'ui-icon-circle-close fl mr5'
                    }
                });
            }
            if (!this.options.buttons.browse) {
                this.browse_button.button("disable").hide();
                g("#" + k + i.runtime + "_container").hide()
            }
            if (!this.options.buttons.start) {
                this.start_button.button("disable").hide()
            }
            if (!this.options.buttons.stop) {
                this.stop_button.button("disable").hide()
            }
            if (!this.options.buttons.reset) {
                this.reset_button.button('disable').hide();
            }
            if (!this.options.buttons.cancel) {
                this.cancel_button.button('disable').hide();
            }
            this.progressbar = g(".plupload_progress_container", this.container);
            if (g.ui.progressbar) {
                this.progressbar.progressbar()
            }
            this.counter = g(".plupload_count", this.element).attr({
                id: k + "_count",
                name: k + "_count"
            });
            j = this.uploader = h[k] = new c.Uploader(g.extend({
                container: k,
                browse_button: k + "_browse"
            }, this.options));
            j.bind("Init", function (l, m) {
                
                i._updateFileList()
                i._updateTotalProgress();
                if (!i.options.unique_names && i.options.rename) {
                    i._enableRenaming()
                }
                if (j.features.dragdrop && i.options.dragdrop) {
                    i._enableDragAndDrop()
                }
                //i.container.attr("title", b("Using runtime: ") + (i.runtime = m.runtime));
                i.start_button.click(function (n) {
                    if((l.total.size/ 1048576).toPrecision(3) > 100){
                        alert('File size error. Min-size 1 Byte and Max-size 100 MB,Please remove some files to proceed.' );
                    }
                    else {
                        if (!g(this).button("option", "disabled")) {
                            i.start()
                            i.browse_button.button("disable")
                            i.cancel_button.button("disable")
                        }
                    }
                    n.preventDefault()
                });
                i.stop_button.click(function (n) {
                    j.stop();
                    i.browse_button.button("enable")
                    i.cancel_button.button("enable")
                    n.preventDefault()
                })
                i.reset_button.click(function (n) {
                    j.splice();
                    n.preventDefault()
                })
                i.cancel_button.click(function () {
                    window.location.href = i.options.return_path;
                })
            });
            if (i.options.max_file_count) {
                j.bind("FilesAdded", function (l, n) {
                    var o = [],
                    m = n.length;
                    var p = l.files.length + m - i.options.max_file_count;
                    if (p > 0) {
                        o = n.splice(m - p, p);
                        l.trigger("Error", {
                            code: i.FILE_COUNT_ERROR,
                            message: b("File count error."),
                            file: o
                        })
                    }
                })
            }
            j.init();
            j.bind("FilesAdded", function (l, m) {
                i._trigger("selected", null, {
                    up: l,
                    files: m
                });
                if (i.options.autostart) {
                    i.start()
                }
            });
            j.bind("FilesRemoved", function (l, m) {
                i._trigger("removed", null, {
                    up: l,
                    files: m
                })
            });
            j.bind("QueueChanged", function (l,m) {
               
                i._updateFileList()
               
            });
            j.bind("StateChanged", function () {
                i._handleState()
            });
            j.bind("UploadFile", function (l, m) {
                i._handleFileStatus(m)
            });
            j.bind("FileUploaded", function (l, m) {
                i._handleFileStatus(m);
                i._trigger("uploaded", null, {
                    up: l,
                    file: m
                })
            });
            j.bind("UploadProgress", function (l, m) {
                g("#" + m.id + " .plupload_file_status", i.element).html(m.percent + "%");
                i._handleFileStatus(m);
                i._updateTotalProgress();
                i._trigger("progress", null, {
                    up: l,
                    file: m
                })
            });
            j.bind("UploadComplete", function (l, m) {
                i._trigger("complete", null, {
                    up: l,
                    files: m
                })
            });
            j.bind("Error", function (l, p) {
                var n = p.file,
                    o, m;
                if (n) {
                    o = "<strong>" + p.message + "</strong>";
                    m = p.details;
                    if (m) {
                        o += " <br /><i>" + p.details + "</i>"
                    } else {
                        switch (p.code) {
                        case c.FILE_EXTENSION_ERROR:
                            m = b("File: %s").replace("%s", n.name);
                            break;
                        case c.FILE_SIZE_ERROR:
                            m = b("File: %f, size: %s").replace(/%([fsm])/g, function (r, q) {
                                switch (q) {
                                case "f":
                                    return n.name;
                                case "s":
                                    return c.formatSize(n.size);
                                }
                            });
                            break;
                        case i.FILE_COUNT_ERROR:
                            m = b("Upload element accepts only %d file(s) at a time. Extra files were stripped.").replace("%d", i.options.max_file_count);
                            break;
                        case c.IMAGE_FORMAT_ERROR:
                            m = c.translate("Image format either wrong or not supported.");
                            break;
                        case c.IMAGE_MEMORY_ERROR:
                            m = c.translate("Runtime ran out of available memory.");
                            break;
                        case c.IMAGE_DIMENSIONS_ERROR:
                            m = c.translate("Resoultion out of boundaries! <b>%s</b> runtime supports images only up to %wx%hpx.").replace(/%([swh])/g, function (r, q) {
                                switch (q) {
                                case "s":
                                    return l.runtime;
                                case "w":
                                    return l.features.maxWidth;
                                case "h":
                                    return l.features.maxHeight
                                }
                            });
                            break;
                        case c.HTTP_ERROR:
                            m = b("Upload URL might be wrong or doesn't exist");
                            break
                        }
                        o += " <br /><i>" + m + "</i>"
                    }
                    i.notify("error", o);
                    jQuery('.plupload_header_content').show()
                    .fadeIn('slow')
                    .animate({
                        opacity: 1.0
                    }, 8000)
                    .fadeOut('slow')
                    i._trigger("error", null, {
                        up: l,
                        file: n,
                        error: o
                    })
                }
            })
        },
        _setOption: function (j, k) {
            var i = this;
            if (j == "buttons" && typeof (k) == "object") {
                k = g.extend(i.options.buttons, k);
                if (!k.browse) {
                    i.browse_button.button("disable").hide();
                    g("#" + i.id + i.runtime + "_container").hide()
                } else {
                    i.browse_button.button("enable").show();
                    g("#" + i.id + i.runtime + "_container").show()
                }
                if (!k.start) {
                    i.start_button.button("disable").hide()
                } else {
                    i.start_button.button("enable").show()
                }
                if (!k.stop) {
                    i.stop_button.button("disable").hide()
                } else {
                    i.start_button.button("enable").show()
                }
                if (!k.reset) {
                    i.stop_button.button('disable').hide();
                } else {
                    i.start_button.button('enable').show();
                }
                if (!k.cancel) {
                    i.cancel_button.button("disable").hide();
                } else {
                    i.cancel_button.button("enable").show();
                }
            }
            i.uploader.settings[j] = k
        },
        start: function () {
            this.uploader.start();            
            this._trigger("start", null)
        },
        stop: function () {
            this.uploader.stop();
            this._trigger("stop", null)
        },
        getFile: function (j) {
            var i;
            if (typeof j === "number") {
                i = this.uploader.files[j]
            } else {
                i = this.uploader.getFile(j)
            }
            return i
        },
        removeFile: function (j) {
            var i = this.getFile(j);
            if (i) {
                this.uploader.removeFile(i)
            }
        },
        clearQueue: function () {
            this.uploader.splice()
        },
        resetQueue: function () {
            this.uploader.stop()
            this.uploader.splice()
            this.uploader.refresh()
            jQuery('.plupload_header_content').hide()
        },
        getUploader: function () {
            return this.uploader
        },
        refresh: function () {
            this.uploader.refresh()
        },
        _handleState: function () {
            var i = this,
                j = this.uploader;
            if (j.state === c.STARTED) {
                g(i.start_button).button("disable");
                g(i.reset_button).button('disable');
                g([]).add(i.stop_button).add(".plupload_started").removeClass("plupload_hidden");
                g(".plupload_upload_status", i.element).text(b("Uploaded %d/%d files").replace("%d/%d", j.total.uploaded + "/" + j.files.length));
                g(".plupload_header_content", i.element).addClass("plupload_header_content_bw")
            } else {
                g([]).add(i.stop_button).add(".plupload_started").addClass("plupload_hidden");
                if (i.options.multiple_queues) {
                    g(i.start_button).button("enable");
                    g(i.reset_button).button("enable");
                    g(".plupload_header_content", i.element).removeClass("plupload_header_content_bw")
                }
                i._updateFileList()
            }
        },
        _handleFileStatus: function (l) {
            var n, j;
            switch (l.status) {
            case c.DONE:
                n = "plupload_done";
                j = "ui-icon ui-icon-circle-check";
                break;
            case c.FAILED:
                n = "ui-state-error plupload_failed";
                j = "ui-icon ui-icon-alert";
                break;
            case c.QUEUED:
                n = "plupload_delete";
                j = "ui-icon ui-icon-circle-close";
                break;
            case c.UPLOADING:
                n = "ui-state-highlight plupload_uploading";
                j = "ui-icon ui-icon-circle-arrow-w";
                var i = g(".plupload_scroll", this.container),
                    m = i.scrollTop(),
                    o = i.height(),
                    k = g("#" + l.id).position().top + g("#" + l.id).height();
                if (o < k) {
                    i.scrollTop(m + k - o)
                }
                break
            }
            n += " ui-state-default plupload_file";
            g("#" + l.id).attr("class", n).find(".ui-icon").attr("class", j)
        },
        _updateTotalProgress: function () {
            var i = this.uploader;
            this.progressbar.progressbar("value", i.total.percent);
            g(".plupload_total_status", this.element).html(i.total.percent + "%");
            g(".plupload_upload_status", this.element).text(b("Uploaded %d/%d files").replace("%d/%d", i.total.uploaded + "/" + i.files.length))
            g('.plupload_file_queue',this.element).text(b('Queued %d files').replace('%d', i.total.queued));
        },
        _updateFileList: function () {
            var j = this,
                n = this.uploader,
                l = this.filelist,
                filename = '',
                ext = '',
                split = '',
                k = 0,
                o, m = this.id + "_",
                i;
            if (g.ui.sortable && this.options.sortable) {
                g("tbody", l).sortable("destroy")
            }
            l.empty();
            g.each(n.files, function (q, p) {
                i = "";
                o = m + k;
                filename = p.name;
                split = /^(.+)(\.(.+))$/.exec(filename);
                if (split) {
                    filename = split[1];
                    ext = split[3]
                }
                if (p.status === c.DONE) {
                    if (p.target_name) {
                        i += '<input type="hidden" name="' + o + '_tmpname" value="' + c.xmlEncode(p.target_name) + '" />'
                    }
                    i += '<input type="hidden" name="' + o + '_name" value="' + c.xmlEncode(filename) + '" />';
                    i += '<input type="hidden" name="' + o + '_status" value="' + (p.status === c.DONE ? "done" : "failed") + '" />';
                    k++;
                    j.counter.val(k)
                }
                l.append('<tr class="ui-state-default plupload_file" id="' + p.id + '"><td class="plupload_cell plupload_file_name" width="65%" title="Click file name to rename and press Enter key .Any change made to the file name when the Status for the file is more than 0%,will not reflect in the system."><span>' + filename + '</span></td><td class="plupload_cell plupload_file_extension" width="10%" ><span>' + ext + '</span></td><td class="plupload_cell plupload_file_status" width="10%">' + p.percent + '%</td><td class="plupload_cell plupload_file_size" width="10%">' + c.formatSize(p.size) + '</td><td class="plupload_cell plupload_file_action" width="5%"><div class="ui-icon"></div>' + i + "</td></tr>");
                j._handleFileStatus(p);
                g("#" + p.id + ".plupload_delete .ui-icon, #" + p.id + ".plupload_done .ui-icon").click(function (r) {
                    g("#" + p.id).remove();
                    n.removeFile(p);
                    r.preventDefault()
                });
                j._trigger("updatelist", null, l)
            });
            g(".plupload_total_file_size", j.element).html(c.formatSize(n.total.size));
            if (n.total.queued === 0) {
                g(".span", j.browse_button).text(b("Add Files"))
            } else {
                g('.plupload_file_queue',j.element).text(b('Queued %d files').replace('%d', n.total.queued));
                //g(".ui-button-text", j.browse_button).text(b("%d files queued").replace("%d", n.total.queued))
            }
            if (n.files.length === (n.total.uploaded + n.total.failed)) {
                j.start_button.button("disable")
                j.reset_button.button("disable")
            } else {
                j.start_button.button("enable")
                j.reset_button.button("enable")
                j.browse_button.button("enable")
                j.cancel_button.button("enable")
            }
            l[0].scrollTop = l[0].scrollHeight;
            j._updateTotalProgress();
            if (!n.files.length && n.features.dragdrop && n.settings.dragdrop) {
               // g("#" + o + "_filelist").append('<tr><td class="plupload_droptext">' + b("Drag files here.") + "</td></tr>")
            } else {
                if (j.options.sortable && g.ui.sortable) {
                    j._enableSortingList()
                }
            }
        },
        _enableRenaming: function () {
            var i = this;
            g(".plupload_file_name span", this.filelist).live("click", function (o) {
                var m = g(o.target),
                    k, n, j, l = "";
                k = i.uploader.getFile(m.parents("tr")[0].id);
                j = k.name;
                n = /^(.+)(\.[^.]+)$/.exec(j);
                if (n) {
                    j = n[1];
                    l = n[2]
                }
                m.hide().after('<input class="plupload_file_rename" type="text" />');
                m.next().val(j).focus().blur(function () {
                    m.show().next().remove()
                }).keydown(function (q) {
                    var p = g(this);
                    if (g.inArray(q.keyCode, [13, 27]) !== -1) {
                        q.preventDefault();
                        if (q.keyCode === 13) {
                            k.name = p.val();
                            m.text(k.name)
                        }
                        p.blur()
                    }
                })
            })
        },
        _enableDragAndDrop: function () {
            //this.filelist.append('<tr><td class="plupload_droptext">' + b("Drag files here.") + "</td></tr>");
            this.filelist.parent().attr("id", this.id + "_dropbox");
            this.uploader.settings.drop_element = this.options.drop_element = this.id + "_dropbox"
        },
        _enableSortingList: function () {
            var j, i = this;
            if (g("tbody tr", this.filelist).length < 2) {
                return
            }
            g("tbody", this.filelist).sortable({
                containment: "parent",
                items: ".plupload_delete",
                helper: function (l, k) {
                    return k.clone(true).find("td:not(.plupload_file_name)").remove().end().css("width", "100%")
                },
                stop: function (p, o) {
                    var l, n, k, m = [];
                    g.each(g(this).sortable("toArray"), function (q, r) {
                        m[m.length] = i.uploader.getFile(r)
                    });
                    m.unshift(m.length);
                    m.unshift(0);
                    Array.prototype.splice.apply(i.uploader.files, m)
                }
            })
        },
        notify: function (j, k) {
            var i = g('<div class="plupload_message "><span class="plupload_message_close ui-icon ui-icon-circle-close" title="' + b("Close") + '"></span><p><span class="ui-icon"></span>' + k + "</p></div>");
            i.addClass("ui-state-" + (j === "error" ? "error" : "highlight")).find("p .ui-icon").addClass("ui-icon-" + (j === "error" ? "alert" : "info")).end().find(".plupload_message_close").click(function () {
                i.remove()
                jQuery('.plupload_header_content').hide()
            }).end();
            g(".plupload_header_content", this.container).append(i)

        },
        destroy: function () {
            g(".plupload_button", this.element).unbind();
            if (g.ui.button) {
                g(".plupload_add, .plupload_start, .plupload_stop", this.container).button("destroy")
            }
            if (g.ui.progressbar) {
                this.progressbar.progressbar("destroy")
            }
            if (g.ui.sortable && this.options.sortable) {
                g("tbody", this.filelist).sortable("destroy")
            }
            this.uploader.destroy();
            this.element.empty().html(this.contents_bak);
            this.contents_bak = "";
            g.Widget.prototype.destroy.apply(this)
        }
    })
}(window, document, plupload, jQuery));
