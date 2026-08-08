(() => {
  "use strict";
  var _,
    it = {
      88578: (_, P, T) => {
        var $ = T(70650);
        class C {
          constructor(t) {
            if (
              (function U(e) {
                return (
                  "object" != typeof e ||
                  void 0 === e.length ||
                  void 0 === e.readUInt8 ||
                  void 0 === e.readUInt16LE ||
                  void 0 === e.readUInt16BE ||
                  void 0 === e.readUInt32LE ||
                  void 0 === e.readUInt32BE ||
                  void 0 === e.readInt32LE ||
                  void 0 === e.readInt32BE
                );
              })(t)
            )
              throw new Error("DataView: Passed buffer type is unsupported.");
            ((this.buffer = t), (this.byteLength = this.buffer.length));
          }
          getUint8(t) {
            return this.buffer.readUInt8(t);
          }
          getUint16(t, n) {
            return n
              ? this.buffer.readUInt16LE(t)
              : this.buffer.readUInt16BE(t);
          }
          getUint32(t, n) {
            return n
              ? this.buffer.readUInt32LE(t)
              : this.buffer.readUInt32BE(t);
          }
          getInt32(t, n) {
            return n ? this.buffer.readInt32LE(t) : this.buffer.readInt32BE(t);
          }
        }
        function G(e, t, n) {
          try {
            return new DataView(e, t, n);
          } catch {
            return new C(e, t, n);
          }
        }
        function E(e, t, n) {
          const r = [];
          for (let i = 0; i < n && t + i < e.byteLength; i++)
            r.push(e.getUint8(t + i));
          return w(r);
        }
        function N(e, t) {
          const n = [];
          let r = 0;
          for (; t + r < e.byteLength; ) {
            const i = e.getUint8(t + r);
            if (0 === i) break;
            (n.push(i), r++);
          }
          return w(n);
        }
        function ue(e, t, n) {
          const r = [];
          for (let i = 0; i < n && t + i < e.byteLength; i += 2)
            r.push(e.getUint16(t + i));
          return (0 === r[r.length - 1] && r.pop(), w(r));
        }
        function st(e, t) {
          const n = e.getUint8(t);
          return [n, E(e, t + 1, n)];
        }
        function w(e) {
          return e.map((t) => String.fromCharCode(t)).join("");
        }
        function I() {
          for (let e = 1; e < arguments.length; e++)
            for (const t in arguments[e]) arguments[0][t] = arguments[e][t];
          return arguments[0];
        }
        function ce(e, t, n) {
          let r = !1;
          Object.defineProperty(e, t, {
            get: () => (
              r ||
                ((r = !0),
                Object.defineProperty(e, t, {
                  configurable: !0,
                  enumerable: !0,
                  value: n.apply(e),
                  writable: !0,
                })),
              e[t]
            ),
            configurable: !0,
            enumerable: !0,
          });
        }
        function ut(e) {
          return typeof btoa < "u"
            ? btoa(
                "string" == typeof e
                  ? e
                  : Array.prototype.reduce.call(
                      new Uint8Array(e),
                      (t, n) => t + String.fromCharCode(n),
                      "",
                    ),
              )
            : typeof Buffer > "u"
              ? void 0
              : typeof Buffer.from < "u"
                ? Buffer.from(e).toString("base64")
                : new Buffer(e).toString("base64");
        }
        function ct(e, t) {
          return new Array(t + 1).join(e);
        }
        const fe = void 0,
          ft = 0;
        function at(e, t, n, r = "string") {
          if (t === ft && "function" == typeof DecompressionStream) {
            const i = new DecompressionStream("deflate"),
              o = new Blob([e]).stream().pipeThrough(i);
            return "dataview" === r
              ? new Response(o).arrayBuffer().then((s) => new DataView(s))
              : new Response(o)
                  .arrayBuffer()
                  .then((s) => new TextDecoder(n).decode(s));
          }
          return void 0 !== t
            ? Promise.reject(`Unknown compression method ${t}.`)
            : e;
        }
        const g = {
          USE_FILE: !0,
          USE_JFIF: !0,
          USE_PNG_FILE: !0,
          USE_EXIF: !0,
          USE_IPTC: !0,
          USE_XMP: !0,
          USE_ICC: !0,
          USE_MPF: !0,
          USE_PHOTOSHOP: !0,
          USE_THUMBNAIL: !0,
          USE_TIFF: !0,
          USE_JPEG: !0,
          USE_PNG: !0,
          USE_HEIC: !0,
          USE_AVIF: !0,
          USE_WEBP: !0,
          USE_GIF: !0,
          USE_MAKER_NOTES: !0,
        };
        function A(e) {
          return e.map((t) => String.fromCharCode(t)).join("");
        }
        function Oe(e) {
          if (e.length >= 8) {
            const t = A(e.slice(0, 8));
            if ("ASCII\0\0\0" === t) return A(e.slice(8));
            if ("JIS\0\0\0\0\0" === t) return "[JIS encoded text]";
            if ("UNICODE\0" === t) return "[Unicode encoded text]";
            if ("\0\0\0\0\0\0\0\0" === t) return "[Undefined encoding]";
          }
          return "Undefined";
        }
        function ae(e) {
          return (
            e[0][0] / e[0][1] +
            e[1][0] / e[1][1] / 60 +
            e[2][0] / e[2][1] / 3600
          );
        }
        const j = {
            BIG_ENDIAN: 19789,
            LITTLE_ENDIAN: 18761,
            getByteOrder: function jn(e, t) {
              if (18761 === e.getUint16(t)) return 18761;
              if (19789 === e.getUint16(t)) return 19789;
              throw new Error("Illegal byte order value. Faulty image.");
            },
          },
          lt_isTiffFile = function vn(e) {
            return (
              !!e &&
              e.byteLength >= 4 &&
              (function Jn(e) {
                const r = e.getUint16(0) === j.LITTLE_ENDIAN;
                return 42 === e.getUint16(2, r);
              })(e)
            );
          },
          lt_findTiffOffsets = function qn() {
            return g.USE_EXIF ? { hasAppMarkers: !0, tiffHeaderOffset: 0 } : {};
          },
          dt_isJpegFile = function dr(e) {
            return !!e && e.byteLength >= wn && e.getUint16(0) === Qn;
          },
          dt_findJpegOffsets = function pr(e) {
            let n,
              r,
              i,
              o,
              s,
              u,
              l,
              f,
              a,
              t = pt;
            for (; t + L + 5 <= e.byteLength; ) {
              if (g.USE_FILE && gr(e, t))
                ((n = e.getUint16(t + y)), (r = t + y));
              else if (g.USE_FILE && mr(e, t))
                ((n = e.getUint16(t + y)), (i = t + y));
              else if (g.USE_JFIF && xr(e, t))
                ((n = e.getUint16(t + y)), (o = t + Vn));
              else if (g.USE_EXIF && _r(e, t))
                ((n = e.getUint16(t + y)), (s = t + er));
              else if (g.USE_XMP && Ir(e, t))
                (l || (l = []), (n = e.getUint16(t + y)), l.push(Ar(t, n)));
              else if (g.USE_XMP && Tr(e, t))
                (l || (l = []), (n = e.getUint16(t + y)), l.push(Pr(t, n)));
              else if (g.USE_IPTC && Cr(e, t))
                ((n = e.getUint16(t + y)), (u = t + tr));
              else if (g.USE_ICC && Er(e, t)) {
                n = e.getUint16(t + y);
                const p = t + Et,
                  m = n - (Et - y),
                  S = e.getUint8(t + St),
                  O = e.getUint8(t + rr);
                (f || (f = []),
                  f.push({
                    offset: p,
                    length: m,
                    chunkNumber: S,
                    chunksTotal: O,
                  }));
              } else if (g.USE_MPF && Sr(e, t))
                ((n = e.getUint16(t + y)), (a = t + nr));
              else {
                if (!Ur(e, t)) {
                  if (br(e, t)) {
                    t++;
                    continue;
                  }
                  break;
                }
                n = e.getUint16(t + y);
              }
              t += y + n;
            }
            return {
              hasAppMarkers: t > pt,
              fileDataOffset: r || i,
              jfifDataOffset: o,
              tiffHeaderOffset: s,
              iptcDataOffset: u,
              xmpChunks: l,
              iccChunks: f,
              mpfDataOffset: a,
            };
          },
          wn = 2,
          Qn = 65496,
          pt = 2,
          L = 4,
          y = 2,
          Vn = 2,
          er = 10,
          tr = 18,
          gt = 33,
          mt = 79,
          Et = 18,
          nr = 8,
          De = "ICC_PROFILE\0",
          St = L + De.length,
          rr = St + 1,
          xt = "MPF\0",
          _t = 65472,
          It = 65474,
          ir = 65476,
          or = 65499,
          sr = 65501,
          ur = 65498,
          ht = 65504,
          Le = 65505,
          Tt = 65506,
          cr = 65517,
          fr = 65519,
          ar = 65534,
          lr = 65535,
          Ft = "JFIF",
          At = "Exif",
          Pt = "http://ns.adobe.com/xap/1.0/\0",
          Ct = "http://ns.adobe.com/xmp/extension/\0",
          Ut = "Photoshop 3.0";
        function gr(e, t) {
          return e.getUint16(t) === _t;
        }
        function mr(e, t) {
          return e.getUint16(t) === It;
        }
        function Er(e, t) {
          const n = De.length;
          return e.getUint16(t) === Tt && E(e, t + L, n) === De;
        }
        function Sr(e, t) {
          const n = xt.length;
          return e.getUint16(t) === Tt && E(e, t + L, n) === xt;
        }
        function xr(e, t) {
          const n = Ft.length;
          return (
            e.getUint16(t) === ht &&
            E(e, t + L, n) === Ft &&
            0 === e.getUint8(t + L + n)
          );
        }
        function _r(e, t) {
          const n = At.length;
          return (
            e.getUint16(t) === Le &&
            E(e, t + L, n) === At &&
            0 === e.getUint8(t + L + n)
          );
        }
        function Ir(e, t) {
          return (
            e.getUint16(t) === Le &&
            (function hr(e, t) {
              return E(e, t + L, Pt.length) === Pt;
            })(e, t)
          );
        }
        function Tr(e, t) {
          return (
            e.getUint16(t) === Le &&
            (function Fr(e, t) {
              return E(e, t + L, Ct.length) === Ct;
            })(e, t)
          );
        }
        function Ar(e, t) {
          return { dataOffset: e + gt, length: t - (gt - y) };
        }
        function Pr(e, t) {
          return { dataOffset: e + mt, length: t - (mt - y) };
        }
        function Cr(e, t) {
          const n = Ut.length;
          return (
            e.getUint16(t) === cr &&
            E(e, t + L, n) === Ut &&
            0 === e.getUint8(t + L + n)
          );
        }
        function Ur(e, t) {
          const n = e.getUint16(t);
          return (
            (n >= ht && n <= fr) ||
            n === ar ||
            n === _t ||
            n === It ||
            n === ir ||
            n === or ||
            n === sr ||
            n === ur
          );
        }
        function br(e, t) {
          return e.getUint16(t) === lr;
        }
        const bt_isPngFile = function Nr(e) {
            return !!e && E(e, 0, Me.length) === Me;
          },
          bt_findPngOffsets = function Rr(e, t) {
            const r = { hasAppMarkers: !1 };
            let i = Me.length;
            for (; i + le + M <= e.byteLength; ) {
              if (g.USE_PNG_FILE && Dr(e, i))
                ((r.hasAppMarkers = !0), (r.pngHeaderOffset = i + b));
              else if (g.USE_XMP && Lr(e, i)) {
                const o = Zr(e, i);
                void 0 !== o &&
                  ((r.hasAppMarkers = !0),
                  (r.xmpChunks = [
                    {
                      dataOffset: o,
                      length: e.getUint32(i + Q) - (o - (i + b)),
                    },
                  ]));
              } else if (Mr(e, i, t)) {
                r.hasAppMarkers = !0;
                const o = E(e, i + X, M);
                (r.pngTextChunks || (r.pngTextChunks = []),
                  r.pngTextChunks.push({
                    length: e.getUint32(i + Q),
                    type: o,
                    offset: i + b,
                  }));
              } else if (Br(e, i))
                ((r.hasAppMarkers = !0), (r.tiffHeaderOffset = i + b));
              else if (g.USE_ICC && t && Gr(e, i)) {
                r.hasAppMarkers = !0;
                const o = e.getUint32(i + Q),
                  s = i + b,
                  {
                    profileName: u,
                    compressionMethod: l,
                    compressedProfileOffset: f,
                  } = Hr(e, s);
                (r.iccChunks || (r.iccChunks = []),
                  r.iccChunks.push({
                    offset: f,
                    length: o - (f - s),
                    chunkNumber: 1,
                    chunksTotal: 1,
                    profileName: u,
                    compressionMethod: l,
                  }));
              } else
                kr(e, i) &&
                  ((r.hasAppMarkers = !0),
                  r.pngChunkOffsets || (r.pngChunkOffsets = []),
                  r.pngChunkOffsets.push(i + Q));
              i += e.getUint32(i + Q) + le + M + 4;
            }
            return r;
          },
          Me = "\x89PNG\r\n\x1a\n",
          le = 4,
          M = 4,
          Q = 0,
          X = le,
          b = le + M,
          Be = "XML:com.adobe.xmp\0",
          Ge = "tEXt",
          v = "iTXt",
          de = "zTXt",
          yt = "pHYs",
          Ot = "tIME",
          yr = "eXIf",
          Or = "iCCP";
        function Dr(e, t) {
          return "IHDR" === E(e, t + X, M);
        }
        function Lr(e, t) {
          return E(e, t + X, M) === v && E(e, t + b, Be.length) === Be;
        }
        function Mr(e, t, n) {
          const r = E(e, t + X, M);
          return r === Ge || r === v || (r === de && n);
        }
        function Br(e, t) {
          return E(e, t + X, M) === yr;
        }
        function Gr(e, t) {
          return E(e, t + X, M) === Or;
        }
        function kr(e, t) {
          const n = [yt, Ot],
            r = E(e, t + X, M);
          return n.includes(r);
        }
        function Zr(e, t) {
          t += b + Be.length + 1 + 1;
          let i = 0;
          for (; i < 2 && t < e.byteLength; ) (0 === e.getUint8(t) && i++, t++);
          if (!(i < 2)) return t;
        }
        function Hr(e, t) {
          const i = N(e, t);
          return {
            profileName: i,
            compressionMethod: e.getUint8((t += i.length + 1)),
            compressedProfileOffset: (t += 1),
          };
        }
        function $r(e, t, n, r, i, o, s, u) {
          if (void 0 === u) return [];
          const l = [];
          let f = n.items;
          for (let a = 0; a < u; a++) {
            const p = { extents: [] };
            ((p.itemId = jr(e, f, t)),
              (f += r.item.itemId),
              (p.constructionMethod =
                1 === t || 2 === t ? 15 & e.getUint16(f) : void 0),
              (f += r.item.constructionMethod),
              (p.dataReferenceIndex = e.getUint16(f)),
              (f += r.item.dataReferenceIndex),
              (p.baseOffset = pe(e, f, r.item.baseOffset)),
              (f += r.item.baseOffset),
              (p.extentCount = e.getUint16(f)),
              (f += r.item.extentCount));
            for (let m = 0; m < p.extentCount; m++) {
              const S = {};
              ((S.extentIndex = vr(e, t, f, s)),
                (f += r.item.extent.extentIndex),
                (S.extentOffset = pe(e, f, i)),
                (f += r.item.extent.extentOffset),
                (S.extentLength = pe(e, f, o)),
                (f += r.item.extent.extentLength),
                p.extents.push(S));
            }
            l.push(p);
          }
          return l;
        }
        function jr(e, t, n) {
          return n < 2 ? e.getUint16(t) : 2 === n ? e.getUint32(t) : void 0;
        }
        function vr(e, t, n, r) {
          if ((1 === t || 2 === t) && r > 0) return pe(e, n, r);
        }
        function pe(e, t, n) {
          return 4 === n
            ? e.getUint32(t)
            : 8 === n
              ? (console.warn(
                  "This file uses an 8-bit offset which is currently not supported by ExifReader. Contact the maintainer to get it fixed.",
                ),
                (function Xr(e, t) {
                  return e.getUint32(t + 4);
                })(e, t))
              : 0;
        }
        const Jr = 1718909296,
          qr = 1768977008,
          wr = 1835365473,
          Qr = 1768714083,
          Vr = 1768517222,
          ei = 1768842853,
          ti = 1768973167,
          ni = 1668246642,
          Nt = 1165519206,
          ke = 1835625829,
          ri = 1970432288;
        function ge(e, t) {
          const { length: o, contentOffset: s } = (function ii(e, t) {
            const s = e.getUint32(t);
            return (function oi(e) {
              return 0 === e;
            })(s)
              ? { length: e.byteLength - t, contentOffset: t + 4 + 4 }
              : (function si(e) {
                    return 1 === e;
                  })(s) &&
                  (function ui(e, t) {
                    return 0 === e.getUint32(t + 8);
                  })(e, t)
                ? { length: e.getUint32(t + 12), contentOffset: t + 4 + 4 + 8 }
                : { length: s, contentOffset: t + 4 + 4 };
          })(e, t);
          if (o < 8) return;
          const u = e.getUint32(t + 4);
          if (u === Jr)
            return (function mi(e, t, n) {
              return { type: "ftyp", majorBrand: E(e, t, 4), length: n };
            })(e, s, o);
          if (u === qr)
            return (function Ei(e, t, n, r) {
              return {
                type: "iprp",
                subBoxes: me(e, n, r - (n - t)),
                length: r,
              };
            })(e, t, s, o);
          if (u === ti)
            return (function Si(e, t, n, r) {
              return {
                type: "ipco",
                properties: me(e, n, r - (n - t)),
                length: r,
              };
            })(e, t, s, o);
          if (u === ni)
            return (function xi(e, t, n) {
              return { type: "colr", icc: _i(e, t), length: n };
            })(e, s, o);
          const l = e.getUint8(s);
          return u === wr
            ? (function Ii(e, t, n, r) {
                return {
                  type: "meta",
                  subBoxes: me(e, n + 3, r - (n + 3 - t)),
                  length: r,
                };
              })(e, t, s + 1, o)
            : u === Qr
              ? (function Yr(e, t, n, r) {
                  const { offsets: o, sizes: s } = (function zr(e, t) {
                      const n = {
                        item: {
                          dataReferenceIndex: 2,
                          extentCount: 2,
                          extent: {},
                        },
                      };
                      (e < 2
                        ? ((n.itemCount = 2), (n.item.itemId = 2))
                        : 2 === e && ((n.itemCount = 4), (n.item.itemId = 4)),
                        (n.item.constructionMethod =
                          1 === e || 2 === e ? 2 : 0));
                      const r = {
                        offsetSize: t,
                        lengthSize: t,
                        baseOffsetSize: t + 1,
                        indexSize: t + 1,
                      };
                      return (
                        (r.itemCount = t + 2),
                        (r.items = r.itemCount + n.itemCount),
                        (r.item = { itemId: 0 }),
                        (r.item.constructionMethod =
                          r.item.itemId + n.item.itemId),
                        (r.item.dataReferenceIndex =
                          r.item.constructionMethod +
                          n.item.constructionMethod),
                        { offsets: r, sizes: n }
                      );
                    })(t, n + 3),
                    u = e.getUint8(o.offsetSize) >> 4;
                  s.item.extent.extentOffset = u;
                  const l = 15 & e.getUint8(o.lengthSize);
                  s.item.extent.extentLength = l;
                  const f = e.getUint8(o.baseOffsetSize) >> 4;
                  s.item.baseOffset = f;
                  const a = (function Kr(e, t, n) {
                    if (1 === n || 2 === n) return 15 & e.getUint8(t);
                  })(e, o.indexSize, t);
                  s.item.extent.extentIndex = void 0 !== a ? a : 0;
                  const p = (function Wr(e, t, n) {
                    return n < 2
                      ? e.getUint16(t)
                      : 2 === n
                        ? e.getUint32(t)
                        : void 0;
                  })(e, o.itemCount, t);
                  return {
                    type: "iloc",
                    items: $r(e, t, o, s, u, l, a, p),
                    length: r,
                  };
                })(e, l, s + 1, o)
              : u === Vr
                ? (function hi(e, t, n, r, i) {
                    const { offsets: o } = (function Ti(e, t) {
                      const r = { entryCount: t + 3 },
                        i = {};
                      return (
                        (i.entryCount = 0 === e ? 2 : 4),
                        (r.itemInfos = r.entryCount + i.entryCount),
                        { offsets: r }
                      );
                    })(n, r);
                    return {
                      type: "iinf",
                      itemInfos: me(e, o.itemInfos, i - (o.itemInfos - t)),
                      length: i,
                    };
                  })(e, t, l, s + 1, o)
                : u === ei
                  ? (function Fi(e, t, n, r, i) {
                      r += 3;
                      const s = { type: "infe", length: i };
                      return (
                        (0 === n || 1 === n) &&
                          ((s.itemId = e.getUint16(r)),
                          (s.itemProtectionIndex = e.getUint16((r += 2))),
                          (s.itemName = N(e, (r += 2))),
                          (r += s.itemName.length + 1)),
                        n >= 2 &&
                          (2 === n
                            ? ((s.itemId = e.getUint16(r)), (r += 2))
                            : 3 === n &&
                              ((s.itemId = e.getUint32(r)), (r += 4)),
                          (s.itemProtectionIndex = e.getUint16(r)),
                          (s.itemType = e.getUint32((r += 2))),
                          (s.itemName = N(e, (r += 4))),
                          (r += s.itemName.length + 1),
                          s.itemType === ke
                            ? ((s.contentType = N(e, r)),
                              t + i > (r += s.contentType.length + 1) &&
                                ((s.contentEncoding = N(e, r)),
                                (r += s.contentEncoding.length + 1)))
                            : s.itemType === ri &&
                              ((s.itemUri = N(e, r)),
                              (r += s.itemUri.length + 1))),
                        s
                      );
                    })(e, t, l, s + 1, o)
                  : { type: void 0, length: o };
        }
        function Rt(e) {
          if (g.USE_EXIF || g.USE_XMP || g.USE_ICC) {
            const t = {},
              n = (function ci(e) {
                let r = 0;
                for (; r + 4 + 4 <= e.byteLength; ) {
                  const i = ge(e, r);
                  if (void 0 === i) break;
                  if ("meta" === i.type) return i;
                  r += i.length;
                }
              })(e);
            return n
              ? (g.USE_EXIF &&
                  (t.tiffHeaderOffset = (function fi(e, t) {
                    try {
                      const n = (function ai(e) {
                          return e.subBoxes
                            .find((t) => "iinf" === t.type)
                            .itemInfos.find((t) => t.itemType === Nt);
                        })(t).itemId,
                        r = Ze(t, n);
                      return (function li(e, t) {
                        return t + 4 + e.getUint32(t);
                      })(e, r.baseOffset + r.extents[0].extentOffset);
                    } catch {
                      return;
                    }
                  })(e, n)),
                g.USE_XMP &&
                  (t.xmpChunks = (function di(e) {
                    try {
                      const t = (function pi(e) {
                          return e.subBoxes
                            .find((t) => "iinf" === t.type)
                            .itemInfos.find(
                              (t) =>
                                t.itemType === ke &&
                                "application/rdf+xml" === t.contentType,
                            );
                        })(e).itemId,
                        n = Ze(e, t),
                        r = Ze(e, t).extents[0];
                      return [
                        {
                          dataOffset: n.baseOffset + r.extentOffset,
                          length: r.extentLength,
                        },
                      ];
                    } catch {
                      return;
                    }
                  })(n)),
                g.USE_ICC &&
                  (t.iccChunks = (function gi(e) {
                    try {
                      const t = e.subBoxes
                        .find((n) => "iprp" === n.type)
                        .subBoxes.find((n) => "ipco" === n.type)
                        .properties.find((n) => "colr" === n.type).icc;
                      if (t) return [t];
                    } catch {}
                  })(n)),
                (t.hasAppMarkers =
                  void 0 !== t.tiffHeaderOffset ||
                  void 0 !== t.xmpChunks ||
                  void 0 !== t.iccChunks),
                t)
              : { hasAppMarkers: !1 };
          }
          return {};
        }
        function Ze(e, t) {
          return e.subBoxes
            .find((n) => "iloc" === n.type)
            .items.find((n) => n.itemId === t);
        }
        function _i(e, t) {
          const r = E(e, t, 4);
          if ("prof" === r || "rICC" === r)
            return {
              offset: t + 4,
              length: e.getUint32(t + 4),
              chunkNumber: 1,
              chunksTotal: 1,
            };
        }
        function me(e, t, n) {
          const r = [Nt, ke],
            i = [];
          let o = t;
          for (; o < t + n; ) {
            const s = ge(e, o);
            if (void 0 === s) break;
            (void 0 !== s.type &&
              (void 0 === s.itemType || -1 !== r.indexOf(s.itemType)) &&
              i.push(s),
              (o += s.length));
          }
          return i;
        }
        const Dt_isHeicFile = function Ai(e) {
            if (!e) return !1;
            const t = [
              "heic",
              "heix",
              "hevc",
              "hevx",
              "heim",
              "heis",
              "hevm",
              "hevs",
              "mif1",
            ];
            try {
              const n = ge(e, 0);
              return n && -1 !== t.indexOf(n.majorBrand);
            } catch {
              return !1;
            }
          },
          Dt_findHeicOffsets = function Pi(e) {
            return Rt(e);
          },
          Lt_isAvifFile = function Ci(e) {
            if (!e) return !1;
            try {
              const t = ge(e, 0);
              return t && "avif" === t.majorBrand;
            } catch {
              return !1;
            }
          },
          Lt_findAvifOffsets = function Ui(e) {
            return Rt(e);
          },
          Mt_isWebpFile = function bi(e) {
            return !!e && "RIFF" === E(e, 0, 4) && "WEBP" === E(e, 8, 4);
          },
          Mt_findOffsets = function yi(e) {
            let u,
              l,
              f,
              a,
              o = 12,
              s = !1;
            for (; o + 8 < e.byteLength; ) {
              const p = E(e, o, 4),
                m = e.getUint32(o + 4, !0);
              (g.USE_EXIF && "EXIF" === p
                ? ((s = !0),
                  (u = "Exif\0\0" === E(e, o + 8, 6) ? o + 8 + 6 : o + 8))
                : g.USE_XMP && "XMP " === p
                  ? ((s = !0), (l = [{ dataOffset: o + 8, length: m }]))
                  : g.USE_ICC && "ICCP" === p
                    ? ((s = !0),
                      (f = [
                        {
                          offset: o + 8,
                          length: m,
                          chunkNumber: 1,
                          chunksTotal: 1,
                        },
                      ]))
                    : "VP8X" === p && ((s = !0), (a = o + 8)),
                (o += 8 + (m % 2 == 0 ? m : m + 1)));
            }
            return {
              hasAppMarkers: s,
              tiffHeaderOffset: u,
              xmpChunks: l,
              iccChunks: f,
              vp8xChunkOffset: a,
            };
          },
          Bt_isGifFile = function Ri(e) {
            return !!e && Ni.includes(E(e, 0, Oi));
          },
          Bt_findOffsets = function Di() {
            return { gifHeaderOffset: 0 };
          },
          Oi = 6,
          Ni = ["GIF87a", "GIF89a"],
          Gt_isXMLFile = function Li(e) {
            return !!e && E(e, kt, Zt.length) === Zt;
          },
          Gt_findOffsets = function Mi(e) {
            const t = [];
            return (
              t.push({ dataOffset: kt, length: e.byteLength }),
              { xmpChunks: t }
            );
          },
          kt = 0,
          Zt = "<?xpacket begin",
          Bi = {
            parseAppMarkers: function Gi(e, t) {
              if (g.USE_TIFF && lt_isTiffFile(e))
                return Y(lt_findTiffOffsets(), "tiff", "TIFF");
              if (g.USE_JPEG && dt_isJpegFile(e))
                return Y(dt_findJpegOffsets(e), "jpeg", "JPEG");
              if (g.USE_PNG && bt_isPngFile(e))
                return Y(bt_findPngOffsets(e, t), "png", "PNG");
              if (g.USE_HEIC && Dt_isHeicFile(e))
                return Y(Dt_findHeicOffsets(e), "heic", "HEIC");
              if (g.USE_AVIF && Lt_isAvifFile(e))
                return Y(Lt_findAvifOffsets(e), "avif", "AVIF");
              if (g.USE_WEBP && Mt_isWebpFile(e))
                return Y(Mt_findOffsets(e), "webp", "WebP");
              if (g.USE_GIF && Bt_isGifFile(e))
                return Y(Bt_findOffsets(e), "gif", "GIF");
              if (g.USE_XMP && Gt_isXMLFile(e))
                return Y(Gt_findOffsets(e), "xml", "XML");
              throw new Error("Invalid image format");
            },
          };
        function Y(e, t, n) {
          return I({}, e, { fileType: { value: t, description: n } });
        }
        const x = {
            ApertureValue: (e) =>
              Math.pow(Math.sqrt(2), e[0] / e[1]).toFixed(2),
            ColorSpace: (e) =>
              1 === e ? "sRGB" : 65535 === e ? "Uncalibrated" : "Unknown",
            ComponentsConfiguration: (e) =>
              e
                .map((t) =>
                  49 === t
                    ? "Y"
                    : 50 === t
                      ? "Cb"
                      : 51 === t
                        ? "Cr"
                        : 52 === t
                          ? "R"
                          : 53 === t
                            ? "G"
                            : 54 === t
                              ? "B"
                              : void 0,
                )
                .join(""),
            Contrast: (e) =>
              0 === e
                ? "Normal"
                : 1 === e
                  ? "Soft"
                  : 2 === e
                    ? "Hard"
                    : "Unknown",
            CustomRendered: (e) =>
              0 === e
                ? "Normal process"
                : 1 === e
                  ? "Custom process"
                  : "Unknown",
            ExposureMode: (e) =>
              0 === e
                ? "Auto exposure"
                : 1 === e
                  ? "Manual exposure"
                  : 2 === e
                    ? "Auto bracket"
                    : "Unknown",
            ExposureProgram: (e) =>
              0 === e
                ? "Undefined"
                : 1 === e
                  ? "Manual"
                  : 2 === e
                    ? "Normal program"
                    : 3 === e
                      ? "Aperture priority"
                      : 4 === e
                        ? "Shutter priority"
                        : 5 === e
                          ? "Creative program"
                          : 6 === e
                            ? "Action program"
                            : 7 === e
                              ? "Portrait mode"
                              : 8 === e
                                ? "Landscape mode"
                                : 9 === e
                                  ? "Bulb"
                                  : "Unknown",
            ExposureTime(e) {
              if (e[0] / e[1] > 0.25) {
                const t = e[0] / e[1];
                return Number.isInteger(t) ? "" + t : t.toFixed(1);
              }
              return 0 !== e[0] ? `1/${Math.round(e[1] / e[0])}` : `0/${e[1]}`;
            },
            FNumber: (e) => "f/" + e[0] / e[1],
            FocalLength: (e) => e[0] / e[1] + " mm",
            FocalPlaneResolutionUnit: (e) =>
              2 === e ? "inches" : 3 === e ? "centimeters" : "Unknown",
            LightSource: (e) =>
              1 === e
                ? "Daylight"
                : 2 === e
                  ? "Fluorescent"
                  : 3 === e
                    ? "Tungsten (incandescent light)"
                    : 4 === e
                      ? "Flash"
                      : 9 === e
                        ? "Fine weather"
                        : 10 === e
                          ? "Cloudy weather"
                          : 11 === e
                            ? "Shade"
                            : 12 === e
                              ? "Daylight fluorescent (D 5700 \u2013 7100K)"
                              : 13 === e
                                ? "Day white fluorescent (N 4600 \u2013 5400K)"
                                : 14 === e
                                  ? "Cool white fluorescent (W 3900 \u2013 4500K)"
                                  : 15 === e
                                    ? "White fluorescent (WW 3200 \u2013 3700K)"
                                    : 17 === e
                                      ? "Standard light A"
                                      : 18 === e
                                        ? "Standard light B"
                                        : 19 === e
                                          ? "Standard light C"
                                          : 20 === e
                                            ? "D55"
                                            : 21 === e
                                              ? "D65"
                                              : 22 === e
                                                ? "D75"
                                                : 23 === e
                                                  ? "D50"
                                                  : 24 === e
                                                    ? "ISO studio tungsten"
                                                    : 255 === e
                                                      ? "Other light source"
                                                      : "Unknown",
            MeteringMode: (e) =>
              1 === e
                ? "Average"
                : 2 === e
                  ? "CenterWeightedAverage"
                  : 3 === e
                    ? "Spot"
                    : 4 === e
                      ? "MultiSpot"
                      : 5 === e
                        ? "Pattern"
                        : 6 === e
                          ? "Partial"
                          : 255 === e
                            ? "Other"
                            : "Unknown",
            ResolutionUnit: (e) =>
              2 === e ? "inches" : 3 === e ? "centimeters" : "Unknown",
            Saturation: (e) =>
              0 === e
                ? "Normal"
                : 1 === e
                  ? "Low saturation"
                  : 2 === e
                    ? "High saturation"
                    : "Unknown",
            SceneCaptureType: (e) =>
              0 === e
                ? "Standard"
                : 1 === e
                  ? "Landscape"
                  : 2 === e
                    ? "Portrait"
                    : 3 === e
                      ? "Night scene"
                      : "Unknown",
            Sharpness: (e) =>
              0 === e
                ? "Normal"
                : 1 === e
                  ? "Soft"
                  : 2 === e
                    ? "Hard"
                    : "Unknown",
            ShutterSpeedValue(e) {
              const t = Math.pow(2, e[0] / e[1]);
              return t <= 1 ? `${Math.round(1 / t)}` : `1/${Math.round(t)}`;
            },
            WhiteBalance: (e) =>
              0 === e
                ? "Auto white balance"
                : 1 === e
                  ? "Manual white balance"
                  : "Unknown",
            XResolution: (e) => "" + Math.round(e[0] / e[1]),
            YResolution: (e) => "" + Math.round(e[0] / e[1]),
          },
          Ht = {
            11: "ProcessingSoftware",
            254: {
              name: "SubfileType",
              description: (e) =>
                ({
                  0: "Full-resolution image",
                  1: "Reduced-resolution image",
                  2: "Single page of multi-page image",
                  3: "Single page of multi-page reduced-resolution image",
                  4: "Transparency mask",
                  5: "Transparency mask of reduced-resolution image",
                  6: "Transparency mask of multi-page image",
                  7: "Transparency mask of reduced-resolution multi-page image",
                  65537: "Alternate reduced-resolution image",
                  4294967295: "Invalid",
                })[e] || "Unknown",
            },
            255: {
              name: "OldSubfileType",
              description: (e) =>
                ({
                  0: "Full-resolution image",
                  1: "Reduced-resolution image",
                  2: "Single page of multi-page image",
                })[e] || "Unknown",
            },
            256: "ImageWidth",
            257: "ImageLength",
            258: "BitsPerSample",
            259: "Compression",
            262: "PhotometricInterpretation",
            263: {
              name: "Thresholding",
              description: (e) =>
                ({
                  1: "No dithering or halftoning",
                  2: "Ordered dither or halfton",
                  3: "Randomized dither",
                })[e] || "Unknown",
            },
            264: "CellWidth",
            265: "CellLength",
            266: {
              name: "FillOrder",
              description: (e) =>
                ({ 1: "Normal", 2: "Reversed" })[e] || "Unknown",
            },
            269: "DocumentName",
            270: "ImageDescription",
            271: "Make",
            272: "Model",
            273: "StripOffsets",
            274: {
              name: "Orientation",
              description: (e) =>
                1 === e
                  ? "top-left"
                  : 2 === e
                    ? "top-right"
                    : 3 === e
                      ? "bottom-right"
                      : 4 === e
                        ? "bottom-left"
                        : 5 === e
                          ? "left-top"
                          : 6 === e
                            ? "right-top"
                            : 7 === e
                              ? "right-bottom"
                              : 8 === e
                                ? "left-bottom"
                                : "Undefined",
            },
            277: "SamplesPerPixel",
            278: "RowsPerStrip",
            279: "StripByteCounts",
            280: "MinSampleValue",
            281: "MaxSampleValue",
            282: { name: "XResolution", description: x.XResolution },
            283: { name: "YResolution", description: x.YResolution },
            284: "PlanarConfiguration",
            285: "PageName",
            286: {
              name: "XPosition",
              description: (e) => "" + Math.round(e[0] / e[1]),
            },
            287: {
              name: "YPosition",
              description: (e) => "" + Math.round(e[0] / e[1]),
            },
            290: {
              name: "GrayResponseUnit",
              description: (e) =>
                ({ 1: "0.1", 2: "0.001", 3: "0.0001", 4: "1e-05", 5: "1e-06" })[
                  e
                ] || "Unknown",
            },
            296: { name: "ResolutionUnit", description: x.ResolutionUnit },
            297: "PageNumber",
            301: "TransferFunction",
            305: "Software",
            306: "DateTime",
            315: "Artist",
            316: "HostComputer",
            317: "Predictor",
            318: {
              name: "WhitePoint",
              description: (e) => e.map((t) => `${t[0]}/${t[1]}`).join(", "),
            },
            319: {
              name: "PrimaryChromaticities",
              description: (e) => e.map((t) => `${t[0]}/${t[1]}`).join(", "),
            },
            321: "HalftoneHints",
            322: "TileWidth",
            323: "TileLength",
            330: "A100DataOffset",
            332: {
              name: "InkSet",
              description: (e) =>
                ({ 1: "CMYK", 2: "Not CMYK" })[e] || "Unknown",
            },
            337: "TargetPrinter",
            338: {
              name: "ExtraSamples",
              description: (e) =>
                ({
                  0: "Unspecified",
                  1: "Associated Alpha",
                  2: "Unassociated Alpha",
                })[e] || "Unknown",
            },
            339: {
              name: "SampleFormat",
              description: (e) => {
                const t = {
                  1: "Unsigned",
                  2: "Signed",
                  3: "Float",
                  4: "Undefined",
                  5: "Complex int",
                  6: "Complex float",
                };
                return Array.isArray(e)
                  ? e.map((n) => t[n] || "Unknown").join(", ")
                  : "Unknown";
              },
            },
            513: "JPEGInterchangeFormat",
            514: "JPEGInterchangeFormatLength",
            529: {
              name: "YCbCrCoefficients",
              description: (e) => e.map((t) => "" + t[0] / t[1]).join("/"),
            },
            530: "YCbCrSubSampling",
            531: {
              name: "YCbCrPositioning",
              description: (e) =>
                1 === e ? "centered" : 2 === e ? "co-sited" : "undefined " + e,
            },
            532: {
              name: "ReferenceBlackWhite",
              description: (e) => e.map((t) => "" + t[0] / t[1]).join(", "),
            },
            700: "ApplicationNotes",
            18246: "Rating",
            18249: "RatingPercent",
            33432: { name: "Copyright", description: (e) => e.join("; ") },
            33550: "PixelScale",
            33723: "IPTC-NAA",
            33920: "IntergraphMatrix",
            33922: "ModelTiePoint",
            34118: "SEMInfo",
            34264: "ModelTransform",
            34377: "PhotoshopSettings",
            34665: "Exif IFD Pointer",
            34675: "ICC_Profile",
            34735: "GeoTiffDirectory",
            34736: "GeoTiffDoubleParams",
            34737: "GeoTiffAsciiParams",
            34853: "GPS Info IFD Pointer",
            40091: { name: "XPTitle", description: ne },
            40092: { name: "XPComment", description: ne },
            40093: { name: "XPAuthor", description: ne },
            40094: { name: "XPKeywords", description: ne },
            40095: { name: "XPSubject", description: ne },
            42112: "GDALMetadata",
            42113: "GDALNoData",
            50341: "PrintIM",
            50707: "DNGBackwardVersion",
            50708: "UniqueCameraModel",
            50709: "LocalizedCameraModel",
            50721: "ColorMatrix1",
            50722: "ColorMatrix2",
            50723: "CameraCalibration1",
            50724: "CameraCalibration2",
            50725: "ReductionMatrix1",
            50726: "ReductionMatrix2",
            50727: "AnalogBalance",
            50728: "AsShotNeutral",
            50729: "AsShotWhiteXY",
            50730: "BaselineExposure",
            50731: "BaselineNoise",
            50732: "BaselineSharpness",
            50734: "LinearResponseLimit",
            50735: "CameraSerialNumber",
            50736: "DNGLensInfo",
            50739: "ShadowScale",
            50741: {
              name: "MakerNoteSafety",
              description: (e) => ({ 0: "Unsafe", 1: "Safe" })[e] || "Unknown",
            },
            50778: {
              name: "CalibrationIlluminant1",
              description: x.LightSource,
            },
            50779: {
              name: "CalibrationIlluminant2",
              description: x.LightSource,
            },
            50781: "RawDataUniqueID",
            50827: "OriginalRawFileName",
            50828: "OriginalRawFileData",
            50831: "AsShotICCProfile",
            50832: "AsShotPreProfileMatrix",
            50833: "CurrentICCProfile",
            50834: "CurrentPreProfileMatrix",
            50879: "ColorimetricReference",
            50885: "SRawType",
            50898: "PanasonicTitle",
            50899: "PanasonicTitle2",
            50931: "CameraCalibrationSig",
            50932: "ProfileCalibrationSig",
            50933: "ProfileIFD",
            50934: "AsShotProfileName",
            50936: "ProfileName",
            50937: "ProfileHueSatMapDims",
            50938: "ProfileHueSatMapData1",
            50939: "ProfileHueSatMapData2",
            50940: "ProfileToneCurve",
            50941: {
              name: "ProfileEmbedPolicy",
              description: (e) =>
                ({
                  0: "Allow Copying",
                  1: "Embed if Used",
                  2: "Never Embed",
                  3: "No Restrictions",
                })[e] || "Unknown",
            },
            50942: "ProfileCopyright",
            50964: "ForwardMatrix1",
            50965: "ForwardMatrix2",
            50966: "PreviewApplicationName",
            50967: "PreviewApplicationVersion",
            50968: "PreviewSettingsName",
            50969: "PreviewSettingsDigest",
            50970: {
              name: "PreviewColorSpace",
              description: (e) =>
                ({
                  1: "Gray Gamma 2.2",
                  2: "sRGB",
                  3: "Adobe RGB",
                  4: "ProPhoto RGB",
                })[e] || "Unknown",
            },
            50971: "PreviewDateTime",
            50972: "RawImageDigest",
            50973: "OriginalRawFileDigest",
            50981: "ProfileLookTableDims",
            50982: "ProfileLookTableData",
            51043: "TimeCodes",
            51044: "FrameRate",
            51058: "TStop",
            51081: "ReelName",
            51089: "OriginalDefaultFinalSize",
            51090: "OriginalBestQualitySize",
            51091: "OriginalDefaultCropSize",
            51105: "CameraLabel",
            51107: {
              name: "ProfileHueSatMapEncoding",
              description: (e) => ({ 0: "Linear", 1: "sRGB" })[e] || "Unknown",
            },
            51108: {
              name: "ProfileLookTableEncoding",
              description: (e) => ({ 0: "Linear", 1: "sRGB" })[e] || "Unknown",
            },
            51109: "BaselineExposureOffset",
            51110: {
              name: "DefaultBlackRender",
              description: (e) => ({ 0: "Auto", 1: "None" })[e] || "Unknown",
            },
            51111: "NewRawImageDigest",
            51112: "RawToPreviewGain",
          };
        function ne(e) {
          return new TextDecoder("utf-16")
            .decode(new Uint8Array(e))
            .replace(/\u0000+$/, "");
        }
        const Zi = {
            0: {
              name: "GPSVersionID",
              description: (e) =>
                2 === e[0] && 2 === e[1] && 0 === e[2] && 0 === e[3]
                  ? "Version 2.2"
                  : "Unknown",
            },
            1: {
              name: "GPSLatitudeRef",
              description: (e) => {
                const t = e.join("");
                return "N" === t
                  ? "North latitude"
                  : "S" === t
                    ? "South latitude"
                    : "Unknown";
              },
            },
            2: { name: "GPSLatitude", description: ae },
            3: {
              name: "GPSLongitudeRef",
              description: (e) => {
                const t = e.join("");
                return "E" === t
                  ? "East longitude"
                  : "W" === t
                    ? "West longitude"
                    : "Unknown";
              },
            },
            4: { name: "GPSLongitude", description: ae },
            5: {
              name: "GPSAltitudeRef",
              description: (e) =>
                0 === e
                  ? "Sea level"
                  : 1 === e
                    ? "Sea level reference (negative value)"
                    : "Unknown",
            },
            6: { name: "GPSAltitude", description: (e) => e[0] / e[1] + " m" },
            7: {
              name: "GPSTimeStamp",
              description: (e) =>
                e
                  .map(([t, n]) => {
                    const r = t / n;
                    return /^\d(\.|$)/.test(`${r}`) ? `0${r}` : r;
                  })
                  .join(":"),
            },
            8: "GPSSatellites",
            9: {
              name: "GPSStatus",
              description: (e) => {
                const t = e.join("");
                return "A" === t
                  ? "Measurement in progress"
                  : "V" === t
                    ? "Measurement Interoperability"
                    : "Unknown";
              },
            },
            10: {
              name: "GPSMeasureMode",
              description: (e) => {
                const t = e.join("");
                return "2" === t
                  ? "2-dimensional measurement"
                  : "3" === t
                    ? "3-dimensional measurement"
                    : "Unknown";
              },
            },
            11: "GPSDOP",
            12: {
              name: "GPSSpeedRef",
              description: (e) => {
                const t = e.join("");
                return "K" === t
                  ? "Kilometers per hour"
                  : "M" === t
                    ? "Miles per hour"
                    : "N" === t
                      ? "Knots"
                      : "Unknown";
              },
            },
            13: "GPSSpeed",
            14: {
              name: "GPSTrackRef",
              description: (e) => {
                const t = e.join("");
                return "T" === t
                  ? "True direction"
                  : "M" === t
                    ? "Magnetic direction"
                    : "Unknown";
              },
            },
            15: "GPSTrack",
            16: {
              name: "GPSImgDirectionRef",
              description: (e) => {
                const t = e.join("");
                return "T" === t
                  ? "True direction"
                  : "M" === t
                    ? "Magnetic direction"
                    : "Unknown";
              },
            },
            17: "GPSImgDirection",
            18: "GPSMapDatum",
            19: {
              name: "GPSDestLatitudeRef",
              description: (e) => {
                const t = e.join("");
                return "N" === t
                  ? "North latitude"
                  : "S" === t
                    ? "South latitude"
                    : "Unknown";
              },
            },
            20: {
              name: "GPSDestLatitude",
              description: (e) =>
                e[0][0] / e[0][1] +
                e[1][0] / e[1][1] / 60 +
                e[2][0] / e[2][1] / 3600,
            },
            21: {
              name: "GPSDestLongitudeRef",
              description: (e) => {
                const t = e.join("");
                return "E" === t
                  ? "East longitude"
                  : "W" === t
                    ? "West longitude"
                    : "Unknown";
              },
            },
            22: {
              name: "GPSDestLongitude",
              description: (e) =>
                e[0][0] / e[0][1] +
                e[1][0] / e[1][1] / 60 +
                e[2][0] / e[2][1] / 3600,
            },
            23: {
              name: "GPSDestBearingRef",
              description: (e) => {
                const t = e.join("");
                return "T" === t
                  ? "True direction"
                  : "M" === t
                    ? "Magnetic direction"
                    : "Unknown";
              },
            },
            24: "GPSDestBearing",
            25: {
              name: "GPSDestDistanceRef",
              description: (e) => {
                const t = e.join("");
                return "K" === t
                  ? "Kilometers"
                  : "M" === t
                    ? "Miles"
                    : "N" === t
                      ? "Knots"
                      : "Unknown";
              },
            },
            26: "GPSDestDistance",
            27: { name: "GPSProcessingMethod", description: Oe },
            28: { name: "GPSAreaInformation", description: Oe },
            29: "GPSDateStamp",
            30: {
              name: "GPSDifferential",
              description: (e) =>
                0 === e
                  ? "Measurement without differential correction"
                  : 1 === e
                    ? "Differential correction applied"
                    : "Unknown",
            },
            31: "GPSHPositioningError",
          },
          Hi = {
            1: "InteroperabilityIndex",
            2: { name: "InteroperabilityVersion", description: (e) => A(e) },
            4096: "RelatedImageFileFormat",
            4097: "RelatedImageWidth",
            4098: "RelatedImageHeight",
          },
          Xi = {
            45056: { name: "MPFVersion", description: (e) => A(e) },
            45057: "NumberOfImages",
            45058: "MPEntry",
            45059: "ImageUIDList",
            45060: "TotalFrames",
          },
          Xt = I({}, Ht, {
            33434: { name: "ExposureTime", description: x.ExposureTime },
            33437: { name: "FNumber", description: x.FNumber },
            34850: { name: "ExposureProgram", description: x.ExposureProgram },
            34852: "SpectralSensitivity",
            34855: "ISOSpeedRatings",
            34856: { name: "OECF", description: () => "[Raw OECF table data]" },
            34858: "TimeZoneOffset",
            34859: "SelfTimerMode",
            34864: {
              name: "SensitivityType",
              description: (e) =>
                ({
                  1: "Standard Output Sensitivity",
                  2: "Recommended Exposure Index",
                  3: "ISO Speed",
                  4: "Standard Output Sensitivity and Recommended Exposure Index",
                  5: "Standard Output Sensitivity and ISO Speed",
                  6: "Recommended Exposure Index and ISO Speed",
                  7: "Standard Output Sensitivity, Recommended Exposure Index and ISO Speed",
                })[e] || "Unknown",
            },
            34865: "StandardOutputSensitivity",
            34866: "RecommendedExposureIndex",
            34867: "ISOSpeed",
            34868: "ISOSpeedLatitudeyyy",
            34869: "ISOSpeedLatitudezzz",
            36864: { name: "ExifVersion", description: (e) => A(e) },
            36867: "DateTimeOriginal",
            36868: "DateTimeDigitized",
            36873: "GooglePlusUploadCode",
            36880: "OffsetTime",
            36881: "OffsetTimeOriginal",
            36882: "OffsetTimeDigitized",
            37121: {
              name: "ComponentsConfiguration",
              description: x.ComponentsConfiguration,
            },
            37122: "CompressedBitsPerPixel",
            37377: {
              name: "ShutterSpeedValue",
              description: x.ShutterSpeedValue,
            },
            37378: { name: "ApertureValue", description: x.ApertureValue },
            37379: "BrightnessValue",
            37380: "ExposureBiasValue",
            37381: {
              name: "MaxApertureValue",
              description: (e) =>
                Math.pow(Math.sqrt(2), e[0] / e[1]).toFixed(2),
            },
            37382: {
              name: "SubjectDistance",
              description: (e) => e[0] / e[1] + " m",
            },
            37383: { name: "MeteringMode", description: x.MeteringMode },
            37384: { name: "LightSource", description: x.LightSource },
            37385: {
              name: "Flash",
              description: (e) =>
                0 === e
                  ? "Flash did not fire"
                  : 1 === e
                    ? "Flash fired"
                    : 5 === e
                      ? "Strobe return light not detected"
                      : 7 === e
                        ? "Strobe return light detected"
                        : 9 === e
                          ? "Flash fired, compulsory flash mode"
                          : 13 === e
                            ? "Flash fired, compulsory flash mode, return light not detected"
                            : 15 === e
                              ? "Flash fired, compulsory flash mode, return light detected"
                              : 16 === e
                                ? "Flash did not fire, compulsory flash mode"
                                : 24 === e
                                  ? "Flash did not fire, auto mode"
                                  : 25 === e
                                    ? "Flash fired, auto mode"
                                    : 29 === e
                                      ? "Flash fired, auto mode, return light not detected"
                                      : 31 === e
                                        ? "Flash fired, auto mode, return light detected"
                                        : 32 === e
                                          ? "No flash function"
                                          : 65 === e
                                            ? "Flash fired, red-eye reduction mode"
                                            : 69 === e
                                              ? "Flash fired, red-eye reduction mode, return light not detected"
                                              : 71 === e
                                                ? "Flash fired, red-eye reduction mode, return light detected"
                                                : 73 === e
                                                  ? "Flash fired, compulsory flash mode, red-eye reduction mode"
                                                  : 77 === e
                                                    ? "Flash fired, compulsory flash mode, red-eye reduction mode, return light not detected"
                                                    : 79 === e
                                                      ? "Flash fired, compulsory flash mode, red-eye reduction mode, return light detected"
                                                      : 89 === e
                                                        ? "Flash fired, auto mode, red-eye reduction mode"
                                                        : 93 === e
                                                          ? "Flash fired, auto mode, return light not detected, red-eye reduction mode"
                                                          : 95 === e
                                                            ? "Flash fired, auto mode, return light detected, red-eye reduction mode"
                                                            : "Unknown",
            },
            37386: { name: "FocalLength", description: x.FocalLength },
            37393: "ImageNumber",
            37394: {
              name: "SecurityClassification",
              description: (e) =>
                ({
                  C: "Confidential",
                  R: "Restricted",
                  S: "Secret",
                  T: "Top Secret",
                  U: "Unclassified",
                })[e] || "Unknown",
            },
            37395: "ImageHistory",
            37396: {
              name: "SubjectArea",
              description: (e) =>
                2 === e.length
                  ? `Location; X: ${e[0]}, Y: ${e[1]}`
                  : 3 === e.length
                    ? `Circle; X: ${e[0]}, Y: ${e[1]}, diameter: ${e[2]}`
                    : 4 === e.length
                      ? `Rectangle; X: ${e[0]}, Y: ${e[1]}, width: ${e[2]}, height: ${e[3]}`
                      : "Unknown",
            },
            37500: {
              name: "MakerNote",
              description: () => "[Raw maker note data]",
            },
            37510: { name: "UserComment", description: Oe },
            37520: "SubSecTime",
            37521: "SubSecTimeOriginal",
            37522: "SubSecTimeDigitized",
            37724: "ImageSourceData",
            37888: {
              name: "AmbientTemperature",
              description: (e) => e[0] / e[1] + " \xb0C",
            },
            37889: { name: "Humidity", description: (e) => e[0] / e[1] + " %" },
            37890: {
              name: "Pressure",
              description: (e) => e[0] / e[1] + " hPa",
            },
            37891: {
              name: "WaterDepth",
              description: (e) => e[0] / e[1] + " m",
            },
            37892: {
              name: "Acceleration",
              description: (e) => e[0] / e[1] + " mGal",
            },
            37893: {
              name: "CameraElevationAngle",
              description: (e) => e[0] / e[1] + " \xb0",
            },
            40960: {
              name: "FlashpixVersion",
              description: (e) => e.map((t) => String.fromCharCode(t)).join(""),
            },
            40961: { name: "ColorSpace", description: x.ColorSpace },
            40962: "PixelXDimension",
            40963: "PixelYDimension",
            40964: "RelatedSoundFile",
            40965: "Interoperability IFD Pointer",
            41483: "FlashEnergy",
            41484: {
              name: "SpatialFrequencyResponse",
              description: () => "[Raw SFR table data]",
            },
            41486: "FocalPlaneXResolution",
            41487: "FocalPlaneYResolution",
            41488: {
              name: "FocalPlaneResolutionUnit",
              description: x.FocalPlaneResolutionUnit,
            },
            41492: {
              name: "SubjectLocation",
              description: ([e, t]) => `X: ${e}, Y: ${t}`,
            },
            41493: "ExposureIndex",
            41495: {
              name: "SensingMethod",
              description: (e) =>
                1 === e
                  ? "Undefined"
                  : 2 === e
                    ? "One-chip color area sensor"
                    : 3 === e
                      ? "Two-chip color area sensor"
                      : 4 === e
                        ? "Three-chip color area sensor"
                        : 5 === e
                          ? "Color sequential area sensor"
                          : 7 === e
                            ? "Trilinear sensor"
                            : 8 === e
                              ? "Color sequential linear sensor"
                              : "Unknown",
            },
            41728: {
              name: "FileSource",
              description: (e) => (3 === e ? "DSC" : "Unknown"),
            },
            41729: {
              name: "SceneType",
              description: (e) =>
                1 === e ? "A directly photographed image" : "Unknown",
            },
            41730: {
              name: "CFAPattern",
              description: () => "[Raw CFA pattern table data]",
            },
            41985: { name: "CustomRendered", description: x.CustomRendered },
            41986: { name: "ExposureMode", description: x.ExposureMode },
            41987: { name: "WhiteBalance", description: x.WhiteBalance },
            41988: {
              name: "DigitalZoomRatio",
              description: (e) =>
                0 === e[0] ? "Digital zoom was not used" : "" + e[0] / e[1],
            },
            41989: {
              name: "FocalLengthIn35mmFilm",
              description: (e) => (0 === e ? "Unknown" : e),
            },
            41990: {
              name: "SceneCaptureType",
              description: x.SceneCaptureType,
            },
            41991: {
              name: "GainControl",
              description: (e) =>
                0 === e
                  ? "None"
                  : 1 === e
                    ? "Low gain up"
                    : 2 === e
                      ? "High gain up"
                      : 3 === e
                        ? "Low gain down"
                        : 4 === e
                          ? "High gain down"
                          : "Unknown",
            },
            41992: { name: "Contrast", description: x.Contrast },
            41993: { name: "Saturation", description: x.Saturation },
            41994: { name: "Sharpness", description: x.Sharpness },
            41995: {
              name: "DeviceSettingDescription",
              description: () => "[Raw device settings table data]",
            },
            41996: {
              name: "SubjectDistanceRange",
              description: (e) =>
                1 === e
                  ? "Macro"
                  : 2 === e
                    ? "Close view"
                    : 3 === e
                      ? "Distant view"
                      : "Unknown",
            },
            42016: "ImageUniqueID",
            42032: "CameraOwnerName",
            42033: "BodySerialNumber",
            42034: {
              name: "LensSpecification",
              description: (e) => {
                const r = `${parseFloat((e[0][0] / e[0][1]).toFixed(5))}-${parseFloat((e[1][0] / e[1][1]).toFixed(5))} mm`;
                return 0 === e[3][1]
                  ? `${r} f/?`
                  : `${r} f/${parseFloat((1 / (e[2][1] / e[2][1] / (e[3][0] / e[3][1]))).toFixed(5))}`;
              },
            },
            42035: "LensMake",
            42036: "LensModel",
            42037: "LensSerialNumber",
            42080: {
              name: "CompositeImage",
              description: (e) =>
                ({
                  1: "Not a Composite Image",
                  2: "General Composite Image",
                  3: "Composite Image Captured While Shooting",
                })[e] || "Unknown",
            },
            42081: "SourceImageNumberOfCompositeImage",
            42082: "SourceExposureTimesOfCompositeImage",
            42240: "Gamma",
            59932: "Padding",
            59933: "OffsetSchema",
            65e3: "OwnerName",
            65001: "SerialNumber",
            65002: "Lens",
            65100: "RawFile",
            65101: "Converter",
            65102: "WhiteBalance",
            65105: "Exposure",
            65106: "Shadows",
            65107: "Brightness",
            65108: "Contrast",
            65109: "Saturation",
            65110: "Sharpness",
            65111: "Smoothness",
            65112: "MoireFilter",
          }),
          He = "0th",
          Yt = "1st",
          zt = "exif",
          Kt = "gps",
          Wt = "interoperability",
          $t = "mpf",
          jt = "canon",
          z = {
            [He]: Xt,
            [Yt]: Ht,
            [zt]: Xt,
            [Kt]: Zi,
            [Wt]: Hi,
            [$t]: g.USE_MPF ? Xi : {},
            [jt]: g.USE_MAKER_NOTES
              ? { 4: { name: "ShotInfo", description: (e) => e } }
              : {},
          },
          vt = { 1: 1, 2: 1, 3: 2, 4: 4, 5: 8, 7: 1, 9: 4, 10: 8, 13: 4 },
          Xe = {
            BYTE: 1,
            ASCII: 2,
            SHORT: 3,
            LONG: 4,
            RATIONAL: 5,
            UNDEFINED: 7,
            SLONG: 9,
            SRATIONAL: 10,
            IFD: 13,
          },
          c = {
            getAsciiValue: function zi(e) {
              return e.map((t) => String.fromCharCode(t));
            },
            getByteAt: Jt,
            getAsciiAt: function Ki(e, t) {
              return e.getUint8(t);
            },
            getShortAt: function Wi(e, t, n) {
              return e.getUint16(t, n === j.LITTLE_ENDIAN);
            },
            getLongAt: Ee,
            getRationalAt: function $i(e, t, n) {
              return [Ee(e, t, n), Ee(e, t + 4, n)];
            },
            getUndefinedAt: function ji(e, t) {
              return Jt(e, t);
            },
            getSlongAt: Ye,
            getSrationalAt: function vi(e, t, n) {
              return [Ye(e, t, n), Ye(e, t + 4, n)];
            },
            getIfdPointerAt: function Ji(e, t, n) {
              return Ee(e, t, n);
            },
            typeSizes: vt,
            tagTypes: Xe,
            getTypeSize: function qi(e) {
              if (void 0 === Xe[e]) throw new Error("No such type found.");
              return vt[Xe[e]];
            },
          };
        function Jt(e, t) {
          return e.getUint8(t);
        }
        function Ee(e, t, n) {
          return e.getUint32(t, n === j.LITTLE_ENDIAN);
        }
        function Ye(e, t, n) {
          return e.getInt32(t, n === j.LITTLE_ENDIAN);
        }
        const wi = {
          1: c.getByteAt,
          2: c.getAsciiAt,
          3: c.getShortAt,
          4: c.getLongAt,
          5: c.getRationalAt,
          7: c.getUndefinedAt,
          9: c.getSlongAt,
          10: c.getSrationalAt,
          13: c.getIfdPointerAt,
        };
        function qt(e, t, n) {
          return t + c.getLongAt(e, t + 4, n);
        }
        function J(e, t, n, r, i, o) {
          const s = c.getTypeSize("SHORT"),
            l = {},
            f = (function Qi(e, t, n) {
              return t + c.getTypeSize("SHORT") <= e.byteLength
                ? c.getShortAt(e, t, n)
                : 0;
            })(e, r, i);
          r += s;
          for (let a = 0; a < f && !(r + 12 > e.byteLength); a++) {
            const p = Vi(e, t, n, r, i, o);
            (void 0 !== p &&
              ((l[p.name] = {
                id: p.id,
                value: p.value,
                description: p.description,
              }),
              "MakerNote" === p.name && (l[p.name].__offset = p.__offset)),
              (r += 12));
          }
          if (g.USE_THUMBNAIL && r < e.byteLength - c.getTypeSize("LONG")) {
            const a = c.getLongAt(e, r, i);
            0 !== a &&
              "0th" === t &&
              (l.Thumbnail = J(e, "1st", n, n + a, i, o));
          }
          return l;
        }
        function Vi(e, t, n, r, i, o) {
          const u = c.getTypeSize("SHORT"),
            l = u + c.getTypeSize("SHORT"),
            f = l + c.getTypeSize("LONG"),
            a = c.getShortAt(e, r, i),
            p = c.getShortAt(e, r + u, i),
            m = c.getLongAt(e, r + l, i);
          let S, O;
          if (void 0 === c.typeSizes[p] || (!o && void 0 === z[t][a])) return;
          (!(function eo(e, t) {
            return c.typeSizes[e] * t <= c.getTypeSize("LONG");
          })(p, m)
            ? ((O = c.getLongAt(e, r + f, i)),
              (S = (function to(e, t, n, r, i) {
                return t + n + c.typeSizes[r] * i <= e.byteLength;
              })(e, n, O, p, m)
                ? wt(e, n + O, p, m, i, 33723 === a)
                : "<faulty value>"))
            : ((O = r + f), (S = wt(e, O, p, m, i))),
            p === c.tagTypes.ASCII &&
              ((S = (function no(e) {
                const t = [];
                let n = 0;
                for (let r = 0; r < e.length; r++)
                  "\0" !== e[r]
                    ? (void 0 === t[n] && (t[n] = ""), (t[n] += e[r]))
                    : n++;
                return t;
              })(S)),
              (S = (function ro(e) {
                try {
                  return e.map((t) => decodeURIComponent(escape(t)));
                } catch {
                  return e;
                }
              })(S))));
          let D = `undefined-${a}`,
            R = S;
          if (void 0 !== z[t][a])
            if (void 0 !== z[t][a].name && void 0 !== z[t][a].description) {
              D = z[t][a].name;
              try {
                R = z[t][a].description(S);
              } catch {
                R = Qt(S);
              }
            } else
              p === c.tagTypes.RATIONAL || p === c.tagTypes.SRATIONAL
                ? ((D = z[t][a]), (R = "" + S[0] / S[1]))
                : ((D = z[t][a]), (R = Qt(S)));
          return { id: a, name: D, value: S, description: R, __offset: O };
        }
        function wt(e, t, n, r, i, o = !1) {
          let s = [];
          o && ((r *= c.typeSizes[n]), (n = c.tagTypes.BYTE));
          for (let u = 0; u < r; u++)
            (s.push(wi[n](e, t, i)), (t += c.typeSizes[n]));
          return (
            n === c.tagTypes.ASCII
              ? (s = c.getAsciiValue(s))
              : 1 === s.length && (s = s[0]),
            s
          );
        }
        function Qt(e) {
          return e instanceof Array ? e.join(", ") : e;
        }
        const Vt = "Exif IFD Pointer",
          en = "GPS Info IFD Pointer",
          tn = "Interoperability IFD Pointer",
          nn = {
            read: function io(e, t, n) {
              const r = j.getByteOrder(e, t);
              let i = (function oo(e, t, n, r) {
                return J(e, "0th", t, qt(e, t, n), n, r);
              })(e, t, r, n);
              return (
                (i = (function so(e, t, n, r, i) {
                  return void 0 !== e[Vt]
                    ? I(e, J(t, "exif", n, n + e[Vt].value, r, i))
                    : e;
                })(i, e, t, r, n)),
                (i = (function uo(e, t, n, r, i) {
                  return void 0 !== e[en]
                    ? I(e, J(t, "gps", n, n + e[en].value, r, i))
                    : e;
                })(i, e, t, r, n)),
                (i = (function co(e, t, n, r, i) {
                  return void 0 !== e[tn]
                    ? I(e, J(t, Wt, n, n + e[tn].value, r, i))
                    : e;
                })(i, e, t, r, n)),
                { tags: i, byteOrder: r }
              );
            },
          },
          fo = {
            read: function ao(e, t, n) {
              const r = j.getByteOrder(e, t);
              return (function lo(e, t, n, r) {
                if (!n.MPEntry) return n;
                const i = [];
                for (
                  let o = 0;
                  o < Math.ceil(n.MPEntry.value.length / V);
                  o++
                ) {
                  i[o] = {};
                  const s = re(
                    n.MPEntry.value,
                    o * V,
                    c.getTypeSize("LONG"),
                    r,
                  );
                  ((i[o].ImageFlags = po(s)),
                    (i[o].ImageFormat = go(s)),
                    (i[o].ImageType = mo(s)));
                  const u = re(
                    n.MPEntry.value,
                    o * V + 4,
                    c.getTypeSize("LONG"),
                    r,
                  );
                  i[o].ImageSize = { value: u, description: "" + u };
                  const l = Eo(o, n.MPEntry, r, t);
                  i[o].ImageOffset = { value: l, description: "" + l };
                  const f = re(
                    n.MPEntry.value,
                    o * V + 12,
                    c.getTypeSize("SHORT"),
                    r,
                  );
                  i[o].DependentImage1EntryNumber = {
                    value: f,
                    description: "" + f,
                  };
                  const a = re(
                    n.MPEntry.value,
                    o * V + 14,
                    c.getTypeSize("SHORT"),
                    r,
                  );
                  ((i[o].DependentImage2EntryNumber = {
                    value: a,
                    description: "" + a,
                  }),
                    (i[o].image = e.buffer.slice(l, l + u)),
                    ce(i[o], "base64", function () {
                      return ut(this.image);
                    }));
                }
                return ((n.Images = i), n);
              })(e, t, J(e, "mpf", t, qt(e, t, r), r, n), r);
            },
          },
          V = 16;
        function re(e, t, n, r) {
          if (r === j.LITTLE_ENDIAN) {
            let o = 0;
            for (let s = 0; s < n; s++) o += e[t + s] << (8 * s);
            return o;
          }
          let i = 0;
          for (let o = 0; o < n; o++) i += e[t + o] << (8 * (n - 1 - o));
          return i;
        }
        function po(e) {
          const t = [(e >> 31) & 1, (e >> 30) & 1, (e >> 29) & 1],
            n = [];
          return (
            t[0] && n.push("Dependent Parent Image"),
            t[1] && n.push("Dependent Child Image"),
            t[2] && n.push("Representative Image"),
            { value: t, description: n.join(", ") || "None" }
          );
        }
        function go(e) {
          const t = (e >> 24) & 7;
          return { value: t, description: 0 === t ? "JPEG" : "Unknown" };
        }
        function mo(e) {
          const t = 16777215 & e;
          return {
            value: t,
            description:
              {
                196608: "Baseline MP Primary Image",
                65537: "Large Thumbnail (VGA equivalent)",
                65538: "Large Thumbnail (Full HD equivalent)",
                131073: "Multi-Frame Image (Panorama)",
                131074: "Multi-Frame Image (Disparity)",
                131075: "Multi-Frame Image (Multi-Angle)",
                0: "Undefined",
              }[t] || "Unknown",
          };
        }
        function Eo(e, t, n, r) {
          return (function So(e) {
            return 0 === e;
          })(e)
            ? 0
            : re(t.value, e * V + 8, c.getTypeSize("LONG"), n) + r;
        }
        const xo = {
          read: function _o(e, t) {
            const n = (function Io(e, t) {
                return c.getShortAt(e, t);
              })(e, t),
              r = (function Ao(e, t, n) {
                if (8 > n) return;
                const o = c.getByteAt(e, t + 7);
                return { value: o, description: "" + o };
              })(e, t, n);
            return {
              "Bits Per Sample": ho(e, t, n),
              "Image Height": To(e, t, n),
              "Image Width": Fo(e, t, n),
              "Color Components": r,
              Subsampling: r && Po(e, t, r.value, n),
            };
          },
        };
        function ho(e, t, n) {
          if (3 > n) return;
          const o = c.getByteAt(e, t + 2);
          return { value: o, description: "" + o };
        }
        function To(e, t, n) {
          if (5 > n) return;
          const o = c.getShortAt(e, t + 3);
          return { value: o, description: `${o}px` };
        }
        function Fo(e, t, n) {
          if (7 > n) return;
          const o = c.getShortAt(e, t + 5);
          return { value: o, description: `${o}px` };
        }
        function Po(e, t, n, r) {
          if (8 + 3 * n > r) return;
          const s = [];
          for (let u = 0; u < n; u++) {
            const l = t + 8 + 3 * u;
            s.push([
              c.getByteAt(e, l),
              c.getByteAt(e, l + 1),
              c.getByteAt(e, l + 2),
            ]);
          }
          return { value: s, description: s.length > 1 ? Co(s) + Uo(s) : "" };
        }
        function Co(e) {
          const t = { 1: "Y", 2: "Cb", 3: "Cr", 4: "I", 5: "Q" };
          return e.map((n) => t[n[0]]).join("");
        }
        function Uo(e) {
          const t = {
            17: "4:4:4 (1 1)",
            18: "4:4:0 (1 2)",
            20: "4:4:1 (1 4)",
            33: "4:2:2 (2 1)",
            34: "4:2:0 (2 2)",
            36: "4:2:1 (2 4)",
            65: "4:1:1 (4 1)",
            66: "4:1:0 (4 2)",
          };
          return 0 === e.length || void 0 === e[0][1] || void 0 === t[e[0][1]]
            ? ""
            : t[e[0][1]];
        }
        const bo = {
          read: function yo(e, t) {
            const n = (function Oo(e, t) {
                return c.getShortAt(e, t);
              })(e, t),
              r = (function Bo(e, t, n) {
                if (15 > n) return;
                const o = c.getByteAt(e, t + 14);
                return { value: o, description: `${o}px` };
              })(e, t, n),
              i = (function Go(e, t, n) {
                if (16 > n) return;
                const o = c.getByteAt(e, t + 15);
                return { value: o, description: `${o}px` };
              })(e, t, n),
              o = {
                "JFIF Version": No(e, t, n),
                "Resolution Unit": Ro(e, t, n),
                XResolution: Lo(e, t, n),
                YResolution: Mo(e, t, n),
                "JFIF Thumbnail Width": r,
                "JFIF Thumbnail Height": i,
              };
            if (void 0 !== r && void 0 !== i) {
              const s = (function ko(e, t, n, r) {
                return 0 === n || 16 + n > r
                  ? void 0
                  : {
                      value: e.buffer.slice(t + 16, t + 16 + n),
                      description: "<24-bit RGB pixel data>",
                    };
              })(e, t, 3 * r.value * i.value, n);
              s && (o["JFIF Thumbnail"] = s);
            }
            for (const s in o) void 0 === o[s] && delete o[s];
            return o;
          },
        };
        function No(e, t, n) {
          if (9 > n) return;
          const o = c.getByteAt(e, t + 7),
            s = c.getByteAt(e, t + 7 + 1);
          return { value: 256 * o + s, description: o + "." + s };
        }
        function Ro(e, t, n) {
          if (10 > n) return;
          const o = c.getByteAt(e, t + 9);
          return { value: o, description: Do(o) };
        }
        function Do(e) {
          return 0 === e
            ? "None"
            : 1 === e
              ? "inches"
              : 2 === e
                ? "cm"
                : "Unknown";
        }
        function Lo(e, t, n) {
          if (12 > n) return;
          const o = c.getShortAt(e, t + 10);
          return { value: o, description: "" + o };
        }
        function Mo(e, t, n) {
          if (14 > n) return;
          const o = c.getShortAt(e, t + 12);
          return { value: o, description: "" + o };
        }
        const K = {
          iptc: {
            256: {
              name: "Model Version",
              description: (e) => ((e[0] << 8) + e[1]).toString(),
            },
            261: { name: "Destination", repeatable: !0 },
            276: {
              name: "File Format",
              description: (e) => ((e[0] << 8) + e[1]).toString(),
            },
            278: {
              name: "File Format Version",
              description: (e) => ((e[0] << 8) + e[1]).toString(),
            },
            286: "Service Identifier",
            296: "Envelope Number",
            306: "Product ID",
            316: "Envelope Priority",
            326: { name: "Date Sent", description: ze },
            336: { name: "Time Sent", description: Ke },
            346: {
              name: "Coded Character Set",
              description: rn,
              encoding_name: rn,
            },
            356: "UNO",
            376: {
              name: "ARM Identifier",
              description: (e) => ((e[0] << 8) + e[1]).toString(),
            },
            378: {
              name: "ARM Version",
              description: (e) => ((e[0] << 8) + e[1]).toString(),
            },
            512: {
              name: "Record Version",
              description: (e) => ((e[0] << 8) + e[1]).toString(),
            },
            515: "Object Type Reference",
            516: "Object Attribute Reference",
            517: "Object Name",
            519: "Edit Status",
            520: {
              name: "Editorial Update",
              description: (e) =>
                "01" === A(e) ? "Additional Language" : "Unknown",
            },
            522: "Urgency",
            524: {
              name: "Subject Reference",
              repeatable: !0,
              description: (e) => {
                const t = A(e).split(":");
                return (
                  t[2] + (t[3] ? "/" + t[3] : "") + (t[4] ? "/" + t[4] : "")
                );
              },
            },
            527: "Category",
            532: { name: "Supplemental Category", repeatable: !0 },
            534: "Fixture Identifier",
            537: { name: "Keywords", repeatable: !0 },
            538: { name: "Content Location Code", repeatable: !0 },
            539: { name: "Content Location Name", repeatable: !0 },
            542: "Release Date",
            547: "Release Time",
            549: "Expiration Date",
            550: "Expiration Time",
            552: "Special Instructions",
            554: {
              name: "Action Advised",
              description: (e) => {
                const t = A(e);
                return "01" === t
                  ? "Object Kill"
                  : "02" === t
                    ? "Object Replace"
                    : "03" === t
                      ? "Object Append"
                      : "04" === t
                        ? "Object Reference"
                        : "Unknown";
              },
            },
            557: { name: "Reference Service", repeatable: !0 },
            559: { name: "Reference Date", repeatable: !0 },
            562: { name: "Reference Number", repeatable: !0 },
            567: { name: "Date Created", description: ze },
            572: { name: "Time Created", description: Ke },
            574: { name: "Digital Creation Date", description: ze },
            575: { name: "Digital Creation Time", description: Ke },
            577: "Originating Program",
            582: "Program Version",
            587: {
              name: "Object Cycle",
              description: (e) => {
                const t = A(e);
                return "a" === t
                  ? "morning"
                  : "p" === t
                    ? "evening"
                    : "b" === t
                      ? "both"
                      : "Unknown";
              },
            },
            592: { name: "By-line", repeatable: !0 },
            597: { name: "By-line Title", repeatable: !0 },
            602: "City",
            604: "Sub-location",
            607: "Province/State",
            612: "Country/Primary Location Code",
            613: "Country/Primary Location Name",
            615: "Original Transmission Reference",
            617: "Headline",
            622: "Credit",
            627: "Source",
            628: "Copyright Notice",
            630: { name: "Contact", repeatable: !0 },
            632: "Caption/Abstract",
            634: { name: "Writer/Editor", repeatable: !0 },
            637: { name: "Rasterized Caption", description: (e) => e },
            642: "Image Type",
            643: {
              name: "Image Orientation",
              description: (e) => {
                const t = A(e);
                return "P" === t
                  ? "Portrait"
                  : "L" === t
                    ? "Landscape"
                    : "S" === t
                      ? "Square"
                      : "Unknown";
              },
            },
            647: "Language Identifier",
            662: {
              name: "Audio Type",
              description: (e) => {
                const t = A(e),
                  n = t.charAt(0),
                  r = t.charAt(1);
                let i = "";
                return (
                  "1" === n ? (i += "Mono") : "2" === n && (i += "Stereo"),
                  "A" === r
                    ? (i += ", actuality")
                    : "C" === r
                      ? (i += ", question and answer session")
                      : "M" === r
                        ? (i += ", music, transmitted by itself")
                        : "Q" === r
                          ? (i += ", response to a question")
                          : "R" === r
                            ? (i += ", raw sound")
                            : "S" === r
                              ? (i += ", scener")
                              : "V" === r
                                ? (i += ", voicer")
                                : "W" === r && (i += ", wrap"),
                  "" !== i ? i : t
                );
              },
            },
            663: {
              name: "Audio Sampling Rate",
              description: (e) => parseInt(A(e), 10) + " Hz",
            },
            664: {
              name: "Audio Sampling Resolution",
              description: (e) => {
                const t = parseInt(A(e), 10);
                return t + (1 === t ? " bit" : " bits");
              },
            },
            665: {
              name: "Audio Duration",
              description: (e) => {
                const t = A(e);
                return t.length >= 6
                  ? t.substr(0, 2) + ":" + t.substr(2, 2) + ":" + t.substr(4, 2)
                  : t;
              },
            },
            666: "Audio Outcue",
            698: "Short Document ID",
            699: "Unique Document ID",
            700: "Owner ID",
            712: {
              name: (e) =>
                2 === e.length
                  ? "ObjectData Preview File Format"
                  : "Record 2 destination",
              description: (e) => {
                if (2 === e.length) {
                  const t = (e[0] << 8) + e[1];
                  return 0 === t
                    ? "No ObjectData"
                    : 1 === t
                      ? "IPTC-NAA Digital Newsphoto Parameter Record"
                      : 2 === t
                        ? "IPTC7901 Recommended Message Format"
                        : 3 === t
                          ? "Tagged Image File Format (Adobe/Aldus Image data)"
                          : 4 === t
                            ? "Illustrator (Adobe Graphics data)"
                            : 5 === t
                              ? "AppleSingle (Apple Computer Inc)"
                              : 6 === t
                                ? "NAA 89-3 (ANPA 1312)"
                                : 7 === t
                                  ? "MacBinary II"
                                  : 8 === t
                                    ? "IPTC Unstructured Character Oriented File Format (UCOFF)"
                                    : 9 === t
                                      ? "United Press International ANPA 1312 variant"
                                      : 10 === t
                                        ? "United Press International Down-Load Message"
                                        : 11 === t
                                          ? "JPEG File Interchange (JFIF)"
                                          : 12 === t
                                            ? "Photo-CD Image-Pac (Eastman Kodak)"
                                            : 13 === t
                                              ? "Microsoft Bit Mapped Graphics File [*.BMP]"
                                              : 14 === t
                                                ? "Digital Audio File [*.WAV] (Microsoft & Creative Labs)"
                                                : 15 === t
                                                  ? "Audio plus Moving Video [*.AVI] (Microsoft)"
                                                  : 16 === t
                                                    ? "PC DOS/Windows Executable Files [*.COM][*.EXE]"
                                                    : 17 === t
                                                      ? "Compressed Binary File [*.ZIP] (PKWare Inc)"
                                                      : 18 === t
                                                        ? "Audio Interchange File Format AIFF (Apple Computer Inc)"
                                                        : 19 === t
                                                          ? "RIFF Wave (Microsoft Corporation)"
                                                          : 20 === t
                                                            ? "Freehand (Macromedia/Aldus)"
                                                            : 21 === t
                                                              ? 'Hypertext Markup Language "HTML" (The Internet Society)'
                                                              : 22 === t
                                                                ? "MPEG 2 Audio Layer 2 (Musicom), ISO/IEC"
                                                                : 23 === t
                                                                  ? "MPEG 2 Audio Layer 3, ISO/IEC"
                                                                  : 24 === t
                                                                    ? "Portable Document File (*.PDF) Adobe"
                                                                    : 25 === t
                                                                      ? "News Industry Text Format (NITF)"
                                                                      : 26 === t
                                                                        ? "Tape Archive (*.TAR)"
                                                                        : 27 ===
                                                                            t
                                                                          ? "Tidningarnas Telegrambyr\xe5 NITF version (TTNITF DTD)"
                                                                          : 28 ===
                                                                              t
                                                                            ? "Ritzaus Bureau NITF version (RBNITF DTD)"
                                                                            : 29 ===
                                                                                t
                                                                              ? "Corel Draw [*.CDR]"
                                                                              : `Unknown format ${t}`;
                }
                return A(e);
              },
            },
            713: {
              name: "ObjectData Preview File Format Version",
              description: (e, t) => {
                const n = {
                    "00": { "00": "1" },
                    "01": { "01": "1", "02": "2", "03": "3", "04": "4" },
                    "02": { "04": "4" },
                    "03": { "01": "5.0", "02": "6.0" },
                    "04": { "01": "1.40" },
                    "05": { "01": "2" },
                    "06": { "01": "1" },
                    11: { "01": "1.02" },
                    20: { "01": "3.1", "02": "4.0", "03": "5.0", "04": "5.5" },
                    21: { "02": "2.0" },
                  },
                  r = A(e);
                if (t["ObjectData Preview File Format"]) {
                  const i = A(t["ObjectData Preview File Format"].value);
                  if (n[i] && n[i][r]) return n[i][r];
                }
                return r;
              },
            },
            714: "ObjectData Preview Data",
            1802: { name: "Size Mode", description: (e) => e[0].toString() },
            1812: {
              name: "Max Subfile Size",
              description: (e) => {
                let t = 0;
                for (let n = 0; n < e.length; n++) t = (t << 8) + e[n];
                return t.toString();
              },
            },
            1882: {
              name: "ObjectData Size Announced",
              description: (e) => {
                let t = 0;
                for (let n = 0; n < e.length; n++) t = (t << 8) + e[n];
                return t.toString();
              },
            },
            1887: {
              name: "Maximum ObjectData Size",
              description: (e) => {
                let t = 0;
                for (let n = 0; n < e.length; n++) t = (t << 8) + e[n];
                return t.toString();
              },
            },
          },
        };
        function ze(e) {
          const t = A(e);
          return t.length >= 8
            ? t.substr(0, 4) + "-" + t.substr(4, 2) + "-" + t.substr(6, 2)
            : t;
        }
        function Ke(e) {
          const t = A(e);
          let n = t;
          return (
            t.length >= 6 &&
              ((n =
                t.substr(0, 2) + ":" + t.substr(2, 2) + ":" + t.substr(4, 2)),
              11 === t.length &&
                (n += t.substr(6, 1) + t.substr(7, 2) + ":" + t.substr(9, 2))),
            n
          );
        }
        function rn(e) {
          const t = A(e);
          return "\x1b%G" === t
            ? "UTF-8"
            : "\x1b%5" === t
              ? "Windows-1252"
              : "\x1b%/G" === t
                ? "UTF-8 Level 1"
                : "\x1b%/H" === t
                  ? "UTF-8 Level 2"
                  : "\x1b%/I" === t
                    ? "UTF-8 Level 3"
                    : "\x1b/A" === t
                      ? "ISO-8859-1"
                      : "\x1b/B" === t
                        ? "ISO-8859-2"
                        : "\x1b/C" === t
                          ? "ISO-8859-3"
                          : "\x1b/D" === t
                            ? "ISO-8859-4"
                            : "\x1b/@" === t
                              ? "ISO-8859-5"
                              : "\x1b/G" === t
                                ? "ISO-8859-6"
                                : "\x1b/F" === t
                                  ? "ISO-8859-7"
                                  : "\x1b/H" === t
                                    ? "ISO-8859-8"
                                    : "Unknown";
        }
        const Zo_get = function Ho() {
            if (typeof TextDecoder < "u") return TextDecoder;
          },
          on = {
            decode: function Xo(e, t) {
              const n = Zo_get();
              if (typeof n < "u" && void 0 !== e)
                try {
                  return new n(e).decode(
                    t instanceof DataView ? t.buffer : Uint8Array.from(t),
                  );
                } catch {}
              return (function Yo(e) {
                try {
                  return decodeURIComponent(escape(e));
                } catch {
                  return e;
                }
              })(t.map((i) => String.fromCharCode(i)).join(""));
            },
            TAG_HEADER_SIZE: 5,
          },
          un = 5,
          We = {
            read: function vo(e, t, n) {
              try {
                if (Array.isArray(e))
                  return cn(
                    new DataView(Uint8Array.from(e).buffer),
                    { size: e.length },
                    0,
                    n,
                  );
                const { naaBlock: r, dataOffset: i } = (function Jo(e, t) {
                  for (; t + 12 <= e.byteLength; ) {
                    const n = qo(e, t);
                    if (wo(n))
                      return { naaBlock: n, dataOffset: t + n.headerSize };
                    t += n.headerSize + n.size + Qo(n);
                  }
                  throw new Error("No IPTC NAA resource block.");
                })(e, t);
                return cn(e, r, i, n);
              } catch {
                return {};
              }
            },
          };
        function qo(e, t) {
          if (943868237 !== e.getUint32(t, !1))
            throw new Error("Not an IPTC resource block.");
          const n = e.getUint8(t + 4 + 2),
            r = (n % 2 == 0 ? n + 1 : n) + 1;
          return {
            headerSize: 6 + r + 4,
            type: e.getUint16(t + 4),
            size: e.getUint32(t + 4 + 2 + r),
          };
        }
        function wo(e) {
          return 1028 === e.type;
        }
        function Qo(e) {
          return e.size % 2 != 0 ? 1 : 0;
        }
        function cn(e, t, n, r) {
          const i = {};
          let o;
          const s = n + t.size;
          for (; n < s && n < e.byteLength; ) {
            const { tag: u, tagSize: l } = Vo(e, n, i, o, r);
            if (null === u) break;
            (u &&
              ("encoding" in u && (o = u.encoding),
              void 0 === i[u.name] || void 0 === u.repeatable
                ? (i[u.name] = {
                    id: u.id,
                    value: u.value,
                    description: u.description,
                  })
                : (i[u.name] instanceof Array ||
                    (i[u.name] = [
                      {
                        id: i[u.name].id,
                        value: i[u.name].value,
                        description: i[u.name].description,
                      },
                    ]),
                  i[u.name].push({
                    id: u.id,
                    value: u.value,
                    description: u.description,
                  }))),
              (n += un + l));
          }
          return i;
        }
        function Vo(e, t, n, r, i) {
          if (
            (function es(e, t) {
              return 28 !== e.getUint8(t);
            })(e, t)
          )
            return { tag: null, tagSize: 0 };
          const u = e.getUint16(t + 1),
            l = e.getUint16(t + 3);
          if (!i && !K.iptc[u]) return { tag: void 0, tagSize: l };
          const f = (function ts(e, t, n) {
              const r = [];
              for (let i = 0; i < n; i++) r.push(e.getUint8(t + i));
              return r;
            })(e, t + un, l),
            a = {
              id: u,
              name: ns(K.iptc[u], u, f),
              value: f,
              description: os(K.iptc[u], f, n, r),
            };
          return (
            (function cs(e) {
              return K.iptc[e] && K.iptc[e].repeatable;
            })(u) && (a.repeatable = !0),
            (function fs(e) {
              return K.iptc[e] && void 0 !== K.iptc[e].encoding_name;
            })(u) && (a.encoding = K.iptc[u].encoding_name(f)),
            { tag: a, tagSize: l }
          );
        }
        function ns(e, t, n) {
          return e
            ? (function rs(e) {
                return "string" == typeof e;
              })(e)
              ? e
              : (function is(e) {
                    return "function" == typeof e.name;
                  })(e)
                ? e.name(n)
                : e.name
            : `undefined-${t}`;
        }
        function os(e, t, n, r) {
          if (
            (function us(e) {
              return e && void 0 !== e.description;
            })(e)
          )
            try {
              return e.description(t, n);
            } catch {}
          return (function ss(e, t) {
            return e && t instanceof Array;
          })(e, t)
            ? on.decode(r, t)
            : t;
        }
        const xe = {
          "tiff:Orientation": (e) =>
            "1" === e
              ? "Horizontal (normal)"
              : "2" === e
                ? "Mirror horizontal"
                : "3" === e
                  ? "Rotate 180"
                  : "4" === e
                    ? "Mirror vertical"
                    : "5" === e
                      ? "Mirror horizontal and rotate 270 CW"
                      : "6" === e
                        ? "Rotate 90 CW"
                        : "7" === e
                          ? "Mirror horizontal and rotate 90 CW"
                          : "8" === e
                            ? "Rotate 270 CW"
                            : e,
          "tiff:ResolutionUnit": (e) => x.ResolutionUnit(parseInt(e, 10)),
          "tiff:XResolution": (e) => ee(x.XResolution, e),
          "tiff:YResolution": (e) => ee(x.YResolution, e),
          "exif:ApertureValue": (e) => ee(x.ApertureValue, e),
          "exif:GPSLatitude": an,
          "exif:GPSLongitude": an,
          "exif:FNumber": (e) => ee(x.FNumber, e),
          "exif:FocalLength": (e) => ee(x.FocalLength, e),
          "exif:FocalPlaneResolutionUnit": (e) =>
            x.FocalPlaneResolutionUnit(parseInt(e, 10)),
          "exif:ColorSpace": (e) =>
            x.ColorSpace(
              (function as(e) {
                return "0x" === e.substring(0, 2)
                  ? parseInt(e.substring(2), 16)
                  : parseInt(e, 10);
              })(e),
            ),
          "exif:ComponentsConfiguration"(e, t) {
            if (/^\d, \d, \d, \d$/.test(t)) {
              const n = t.split(", ").map((r) => r.charCodeAt(0));
              return x.ComponentsConfiguration(n);
            }
            return t;
          },
          "exif:Contrast": (e) => x.Contrast(parseInt(e, 10)),
          "exif:CustomRendered": (e) => x.CustomRendered(parseInt(e, 10)),
          "exif:ExposureMode": (e) => x.ExposureMode(parseInt(e, 10)),
          "exif:ExposureProgram": (e) => x.ExposureProgram(parseInt(e, 10)),
          "exif:ExposureTime": (e) =>
            fn(e)
              ? x.ExposureTime(e.split("/").map((t) => parseInt(t, 10)))
              : e,
          "exif:MeteringMode": (e) => x.MeteringMode(parseInt(e, 10)),
          "exif:Saturation": (e) => x.Saturation(parseInt(e, 10)),
          "exif:SceneCaptureType": (e) => x.SceneCaptureType(parseInt(e, 10)),
          "exif:Sharpness": (e) => x.Sharpness(parseInt(e, 10)),
          "exif:ShutterSpeedValue": (e) => ee(x.ShutterSpeedValue, e),
          "exif:WhiteBalance": (e) => x.WhiteBalance(parseInt(e, 10)),
        };
        function ee(e, t) {
          return fn(t) ? e(t.split("/")) : t;
        }
        function fn(e) {
          return /^-?\d+\/-?\d+$/.test(e);
        }
        function an(e) {
          const [t, n] = e.split(",");
          if (void 0 !== t && void 0 !== n) {
            const r = parseFloat(t),
              i = parseFloat(n),
              o = n.charAt(n.length - 1);
            if (!Number.isNaN(r) && !Number.isNaN(i))
              return "" + (r + i / 60) + o;
          }
          return e;
        }
        const ls_get = function ds() {
            if (typeof DOMParser < "u") return new DOMParser();
            try {
              const {
                DOMParser: e,
                onErrorStopParsing: t,
              } = require("@xmldom/xmldom");
              return new e({ onError: t });
            } catch {
              return;
            }
          },
          ln = {
            read: function ps(e, t) {
              const n = {};
              if ("string" == typeof e) return (_e(n, e), n);
              const [r, i] = (function gs(e, t) {
                  if (0 === t.length) return [];
                  const n = [$e(e, t.slice(0, 1))];
                  return (t.length > 1 && n.push($e(e, t.slice(1))), n);
                })(e, t),
                o = _e(n, r);
              if (i) {
                const s = _e(n, i);
                !o && !s && (delete n._raw, _e(n, $e(e, t)));
              }
              return n;
            },
          };
        function $e(e, t) {
          const n = t.reduce((o, s) => o + s.length, 0),
            r = new Uint8Array(n);
          let i = 0;
          for (let o = 0; o < t.length; o++) {
            const s = t[o],
              u = e.buffer.slice(s.dataOffset, s.dataOffset + s.length);
            (r.set(new Uint8Array(u), i), (i += s.length));
          }
          return new DataView(r.buffer);
        }
        function _e(e, t) {
          try {
            const { doc: n, raw: r } = (function ms(e) {
              const t = ls_get();
              if (!t)
                throw (
                  console.warn(
                    "Warning: DOMParser is not available. It is needed to be able to parse XMP tags.",
                  ),
                  new Error()
                );
              const n = "string" == typeof e ? e : E(e, 0, e.byteLength),
                r = t.parseFromString(
                  (function Es(e) {
                    return e
                      .replace(/^.+(<\?xpacket begin)/, "$1")
                      .replace(/(<\?xpacket end=".*"\?>).+$/, "$1");
                  })(n),
                  "application/xml",
                );
              if ("parsererror" === r.documentElement.nodeName)
                throw new Error(r.documentElement.textContent);
              return { doc: r, raw: n };
            })(t);
            return ((e._raw = (e._raw || "") + r), I(e, gn(pn(dn(n), !0))), !0);
          } catch {
            return !1;
          }
        }
        function dn(e) {
          for (let t = 0; t < e.childNodes.length; t++) {
            if ("x:xmpmeta" === e.childNodes[t].tagName)
              return dn(e.childNodes[t]);
            if ("rdf:RDF" === e.childNodes[t].tagName) return e.childNodes[t];
          }
          throw new Error();
        }
        function pn(e, t = !1) {
          const n = (function Ss(e) {
            const t = [];
            for (let n = 0; n < e.childNodes.length; n++)
              t.push(e.childNodes[n]);
            return t;
          })(e);
          return (function xs(e) {
            return 1 === e.length && "#text" === e[0].nodeName;
          })(n)
            ? t
              ? {}
              : (function _s(e) {
                  return e.nodeValue;
                })(n[0])
            : (function Is(e) {
                const t = {};
                return (
                  e.forEach((n) => {
                    if (
                      (function hs(e) {
                        return e.nodeName && "#text" !== e.nodeName;
                      })(n)
                    ) {
                      const r = (function Ts(e) {
                        return { attributes: Fs(e), value: pn(e) };
                      })(n);
                      void 0 !== t[n.nodeName]
                        ? (Array.isArray(t[n.nodeName]) ||
                            (t[n.nodeName] = [t[n.nodeName]]),
                          t[n.nodeName].push(r))
                        : (t[n.nodeName] = r);
                    }
                  }),
                  t
                );
              })(n);
        }
        function Fs(e) {
          const t = {};
          for (let n = 0; n < e.attributes.length; n++)
            t[e.attributes[n].nodeName] = decodeURIComponent(
              escape(e.attributes[n].value),
            );
          return t;
        }
        function gn(e) {
          const t = {};
          if ("string" == typeof e) return e;
          for (const n in e) {
            let r = e[n];
            (Array.isArray(r) || (r = [r]),
              r.forEach((i) => {
                (I(t, je(i.attributes)),
                  "object" == typeof i.value && I(t, mn(i.value)));
              }));
          }
          return t;
        }
        function je(e) {
          const t = {};
          for (const n in e)
            try {
              As(n) &&
                (t[he(n)] = {
                  value: e[n],
                  attributes: {},
                  description: Z(e[n], n),
                });
            } catch {}
          return t;
        }
        function As(e) {
          return "rdf:parseType" !== e && !Ie(e);
        }
        function Ie(e) {
          return "xmlns" === e.split(":")[0];
        }
        function he(e) {
          return /^MicrosoftPhoto(_\d+_)?:Rating$/i.test(e)
            ? "RatingPercent"
            : e.split(":")[1];
        }
        function Z(e, t = void 0) {
          if (Array.isArray(e)) {
            const n = (function Ps(e) {
              return e
                .map((t) => Z(void 0 !== t.value ? t.value : t))
                .join(", ");
            })(e);
            return t && "function" == typeof xe[t] ? xe[t](e, n) : n;
          }
          if ("object" == typeof e)
            return (function Cs(e) {
              const t = [];
              for (const n in e) t.push(`${Us(n)}: ${Z(e[n].value)}`);
              return t.join("; ");
            })(e);
          try {
            return t && "function" == typeof xe[t]
              ? xe[t](e)
              : decodeURIComponent(escape(e));
          } catch {
            return e;
          }
        }
        function Us(e) {
          return "CiAdrCity" === e
            ? "CreatorCity"
            : "CiAdrCtry" === e
              ? "CreatorCountry"
              : "CiAdrExtadr" === e
                ? "CreatorAddress"
                : "CiAdrPcode" === e
                  ? "CreatorPostalCode"
                  : "CiAdrRegion" === e
                    ? "CreatorRegion"
                    : "CiEmailWork" === e
                      ? "CreatorWorkEmail"
                      : "CiTelWork" === e
                        ? "CreatorWorkPhone"
                        : "CiUrlWork" === e
                          ? "CreatorWorkUrl"
                          : e;
        }
        function mn(e) {
          const t = {};
          for (const n in e)
            try {
              Ie(n) || (t[he(n)] = bs(e[n], n));
            } catch {}
          return t;
        }
        function bs(e, t) {
          return (function Os(e) {
            return Array.isArray(e);
          })(e)
            ? (function Ns(e, t) {
                return ve(e[e.length - 1], t);
              })(e, t)
            : (function ys(e) {
                  return (
                    "Resource" === e.attributes["rdf:parseType"] &&
                    "string" == typeof e.value &&
                    "" === e.value.trim()
                  );
                })(e)
              ? { value: "", attributes: {}, description: "" }
              : En(e)
                ? Sn(e, t)
                : xn(e)
                  ? _n(e, t)
                  : In(e)
                    ? hn(e, t)
                    : (function Ls(e) {
                          return void 0 !== Tn(e.value);
                        })(e)
                      ? (function Ms(e, t) {
                          let n = Tn(e.value).value["rdf:li"];
                          const r = oe(e),
                            i = [];
                          return (
                            void 0 === n
                              ? (n = [])
                              : Array.isArray(n) || (n = [n]),
                            n.forEach((o) => {
                              i.push(
                                (function Bs(e) {
                                  return En(e)
                                    ? Sn(e)
                                    : xn(e)
                                      ? _n(e).value
                                      : In(e)
                                        ? hn(e).value
                                        : ve(e);
                                })(o),
                              );
                            }),
                            { value: i, attributes: r, description: Z(i, t) }
                          );
                        })(e, t)
                      : ve(e, t);
        }
        function En(e) {
          return (
            ("Resource" === e.attributes["rdf:parseType"] &&
              void 0 !== e.value["rdf:value"]) ||
            (void 0 !== e.value["rdf:Description"] &&
              void 0 !== e.value["rdf:Description"].value["rdf:value"])
          );
        }
        function Sn(e, t) {
          const n = oe(e);
          (void 0 !== e.value["rdf:Description"] &&
            (e = e.value["rdf:Description"]),
            I(
              n,
              oe(e),
              (function Rs(e) {
                const t = {};
                for (const n in e.value)
                  "rdf:value" !== n && !Ie(n) && (t[he(n)] = e.value[n].value);
                return t;
              })(e),
            ));
          const r = (function Ds(e) {
            return Fn(e.value["rdf:value"]) || e.value["rdf:value"].value;
          })(e);
          return { value: r, attributes: n, description: Z(r, t) };
        }
        function oe(e) {
          const t = {};
          for (const n in e.attributes)
            "rdf:parseType" !== n &&
              "rdf:resource" !== n &&
              !Ie(n) &&
              (t[he(n)] = e.attributes[n]);
          return t;
        }
        function xn(e) {
          return (
            "Resource" === e.attributes["rdf:parseType"] ||
            (void 0 !== e.value["rdf:Description"] &&
              void 0 === e.value["rdf:Description"].value["rdf:value"])
          );
        }
        function _n(e, t) {
          const n = { value: {}, attributes: {} };
          return (
            void 0 !== e.value["rdf:Description"] &&
              (I(n.value, je(e.value["rdf:Description"].attributes)),
              I(n.attributes, oe(e)),
              (e = e.value["rdf:Description"])),
            I(n.value, mn(e.value)),
            (n.description = Z(n.value, t)),
            n
          );
        }
        function In(e) {
          return (
            0 === Object.keys(e.value).length &&
            void 0 === e.attributes["xml:lang"] &&
            void 0 === e.attributes["rdf:resource"]
          );
        }
        function hn(e, t) {
          const n = je(e.attributes);
          return { value: n, attributes: {}, description: Z(n, t) };
        }
        function Tn(e) {
          return e["rdf:Bag"] || e["rdf:Seq"] || e["rdf:Alt"];
        }
        function ve(e, t) {
          const n = Fn(e) || gn(e.value);
          return { value: n, attributes: oe(e), description: Z(n, t) };
        }
        function Fn(e) {
          return e.attributes && e.attributes["rdf:resource"];
        }
        const H_CLOSED_SUBPATH_LENGTH = 0,
          H_CLOSED_SUBPATH_BEZIER_LINKED = 1,
          H_CLOSED_SUBPATH_BEZIER_UNLINKED = 2,
          H_OPEN_SUBPATH_LENGTH = 3,
          H_OPEN_SUBPATH_BEZIER_LINKED = 4,
          H_OPEN_SUBPATH_BEZIER_UNLINKED = 5,
          H_FILL_RULE = 6,
          H_CLIPBOARD = 7,
          H_INITIAL_FILL_RULE = 8,
          Je = {
            2e3: {
              name: "PathInformation",
              description: function Gs(e) {
                const n = {},
                  r = [];
                for (let i = 0; i < e.byteLength; i += 26) {
                  const o = c.getShortAt(e, i);
                  qe[o] &&
                    (n[o] || (n[o] = qe[o].description),
                    r.push({ type: o, path: qe[o].path(e, i + 2) }));
                }
                return JSON.stringify({ types: n, paths: r });
              },
            },
            2999: {
              name: "ClippingPathName",
              description(e) {
                const [, t] = st(e, 0);
                return t;
              },
            },
          },
          qe = {
            [H_CLOSED_SUBPATH_LENGTH]: {
              description: "Closed subpath length",
              path: (e, t) => [c.getShortAt(e, t)],
            },
            [H_CLOSED_SUBPATH_BEZIER_LINKED]: {
              description: "Closed subpath Bezier knot, linked",
              path: Te,
            },
            [H_CLOSED_SUBPATH_BEZIER_UNLINKED]: {
              description: "Closed subpath Bezier knot, unlinked",
              path: Te,
            },
            [H_OPEN_SUBPATH_LENGTH]: {
              description: "Open subpath length",
              path: (e, t) => [c.getShortAt(e, t)],
            },
            [H_OPEN_SUBPATH_BEZIER_LINKED]: {
              description: "Open subpath Bezier knot, linked",
              path: Te,
            },
            [H_OPEN_SUBPATH_BEZIER_UNLINKED]: {
              description: "Open subpath Bezier knot, unlinked",
              path: Te,
            },
            [H_FILL_RULE]: { description: "Path fill rule", path: () => [] },
            [H_INITIAL_FILL_RULE]: {
              description: "Initial fill rule",
              path: (e, t) => [c.getShortAt(e, t)],
            },
            [H_CLIPBOARD]: {
              description: "Clipboard",
              path: function Zs(e, t) {
                return [
                  [q(e, t, 8), q(e, t + 4, 8), q(e, t + 8, 8), q(e, t + 12, 8)],
                  q(e, t + 16, 8),
                ];
              },
            },
          };
        function Te(e, t) {
          const r = [];
          for (let i = 0; i < 24; i += 8) r.push(ks(e, t + i));
          return r;
        }
        function ks(e, t) {
          const n = q(e, t, 8);
          return [q(e, t + 4, 8), n];
        }
        function q(e, t, n) {
          const r = c.getLongAt(e, t),
            i = r >>> 31 ? -1 : 1,
            o = (2130706432 & r) >>> (32 - n),
            s = r & parseInt(ct("1", 32 - n), 2);
          return (
            i *
            (function $n(e, t) {
              return (
                parseInt(e.replace(".", ""), t) /
                Math.pow(t, (e.split(".")[1] || "").length)
              );
            })(
              o.toString(2) +
                "." +
                (function Wn(e, t, n) {
                  return ct(n, t - e.length) + e;
                })(s.toString(2), 32 - n, "0"),
              2,
            )
          );
        }
        const Hs = {
            read: function zs(e, t) {
              const n = G(new Uint8Array(e).buffer),
                r = {};
              let i = 0;
              for (; i < e.length; ) {
                const o = E(n, i, Cn);
                i += Cn;
                const s = c.getShortAt(n, i);
                i += Xs;
                const { tagName: u, tagNameSize: l } = Ks(n, i);
                i += l;
                const f = c.getLongAt(n, i);
                if (((i += Ys), o === Pn)) {
                  const a = G(n.buffer, i, f),
                    p = { id: s, value: E(a, 0, f) };
                  if (Je[s]) {
                    try {
                      p.description = Je[s].description(a);
                    } catch {
                      p.description = "<no description formatter>";
                    }
                    r[u || Je[s].name] = p;
                  } else t && (r[`undefined-${s}`] = p);
                }
                i += f + (f % 2);
              }
              return r;
            },
          },
          Pn = "8BIM",
          Xs = 2,
          Ys = 4,
          Cn = Pn.length;
        function Ks(e, t) {
          const [n, r] = st(e, t);
          return { tagName: r, tagNameSize: 1 + n + (n % 2 == 0 ? 1 : 0) };
        }
        const Un = {
            desc: { name: "ICC Description" },
            cprt: { name: "ICC Copyright" },
            dmdd: { name: "ICC Device Model Description" },
            vued: { name: "ICC Viewing Conditions Description" },
            dmnd: { name: "ICC Device Manufacturer for Display" },
            tech: { name: "Technology" },
          },
          bn = {
            4: {
              name: "Preferred CMM type",
              value: (e, t) => E(e, t, 4),
              description: (e) => (null !== e ? we(e) : ""),
            },
            8: {
              name: "Profile Version",
              value: (e, t) =>
                e.getUint8(t).toString(10) +
                "." +
                (e.getUint8(t + 1) >> 4).toString(10) +
                "." +
                (e.getUint8(t + 1) % 16).toString(10),
            },
            12: {
              name: "Profile/Device class",
              value: (e, t) => E(e, t, 4),
              description: (e) => {
                switch (e.toLowerCase()) {
                  case "scnr":
                    return "Input Device profile";
                  case "mntr":
                    return "Display Device profile";
                  case "prtr":
                    return "Output Device profile";
                  case "link":
                    return "DeviceLink profile";
                  case "abst":
                    return "Abstract profile";
                  case "spac":
                    return "ColorSpace profile";
                  case "nmcl":
                    return "NamedColor profile";
                  case "cenc":
                    return "ColorEncodingSpace profile";
                  case "mid ":
                    return "MultiplexIdentification profile";
                  case "mlnk":
                    return "MultiplexLink profile";
                  case "mvis":
                    return "MultiplexVisualization profile";
                  default:
                    return e;
                }
              },
            },
            16: { name: "Color Space", value: (e, t) => E(e, t, 4) },
            20: { name: "Connection Space", value: (e, t) => E(e, t, 4) },
            24: {
              name: "ICC Profile Date",
              value: (e, t) =>
                (function Ws(e, t) {
                  const n = e.getUint16(t),
                    r = e.getUint16(t + 2) - 1,
                    i = e.getUint16(t + 4),
                    o = e.getUint16(t + 6),
                    s = e.getUint16(t + 8),
                    u = e.getUint16(t + 10);
                  return new Date(Date.UTC(n, r, i, o, s, u));
                })(e, t).toISOString(),
            },
            36: {
              name: "ICC Signature",
              value: (e, t) =>
                (function $s(e) {
                  return String.fromCharCode.apply(null, new Uint8Array(e));
                })(e.buffer.slice(t, t + 4)),
            },
            40: {
              name: "Primary Platform",
              value: (e, t) => E(e, t, 4),
              description: (e) => we(e),
            },
            48: {
              name: "Device Manufacturer",
              value: (e, t) => E(e, t, 4),
              description: (e) => we(e),
            },
            52: { name: "Device Model Number", value: (e, t) => E(e, t, 4) },
            64: {
              name: "Rendering Intent",
              value: (e, t) => e.getUint32(t),
              description: (e) => {
                switch (e) {
                  case 0:
                    return "Perceptual";
                  case 1:
                    return "Relative Colorimetric";
                  case 2:
                    return "Saturation";
                  case 3:
                    return "Absolute Colorimetric";
                  default:
                    return e;
                }
              },
            },
            80: { name: "Profile Creator", value: (e, t) => E(e, t, 4) },
          };
        function we(e) {
          switch (e.toLowerCase()) {
            case "appl":
              return "Apple";
            case "adbe":
              return "Adobe";
            case "msft":
              return "Microsoft";
            case "sunw":
              return "Sun Microsystems";
            case "sgi":
              return "Silicon Graphics";
            case "tgnt":
              return "Taligent";
            default:
              return e;
          }
        }
        const yn = {
            read: function tu(e, t, n) {
              return n && t[0].compressionMethod !== fe
                ? (function nu(e, t) {
                    if (
                      !(function ru(e) {
                        return e === ft;
                      })(t[0].compressionMethod)
                    )
                      return {};
                    return at(
                      new DataView(
                        e.buffer.slice(t[0].offset, t[0].offset + t[0].length),
                      ),
                      t[0].compressionMethod,
                      "utf-8",
                      "dataview",
                    )
                      .then(On)
                      .catch(() => ({}));
                  })(e, t)
                : (function iu(e, t) {
                    try {
                      const n = t.reduce((s, u) => s + u.length, 0),
                        r = new Uint8Array(n);
                      let i = 0;
                      const o = (function ou(e) {
                        return Array.isArray(e)
                          ? new DataView(Uint8Array.from(e).buffer).buffer
                          : e.buffer;
                      })(e);
                      for (let s = 1; s <= t.length; s++) {
                        const u = t.find((a) => a.chunkNumber === s);
                        if (!u) throw new Error(`ICC chunk ${s} not found`);
                        const l = o.slice(u.offset, u.offset + u.length),
                          f = new Uint8Array(l);
                        (r.set(f, i), (i += f.length));
                      }
                      return On(new DataView(r.buffer));
                    } catch {
                      return {};
                    }
                  })(e, t);
            },
          },
          js = 84,
          vs = 128,
          Js = "acsp",
          qs = "desc",
          ws = "mluc",
          Qs = "text",
          Vs = "sig ",
          eu = 12;
        function uu(e, t) {
          return e.length < t + eu;
        }
        function On(e) {
          const t = e.buffer,
            n = e.getUint32();
          if (e.byteLength !== n)
            throw new Error("ICC profile length not matching");
          if (e.length < js) throw new Error("ICC profile too short");
          const r = {},
            i = Object.keys(bn);
          for (let l = 0; l < i.length; l++) {
            const f = i[l],
              a = bn[f],
              p = a.value(e, parseInt(f, 10));
            let m = p;
            (a.description && (m = a.description(p)),
              (r[a.name] = { value: p, description: m }));
          }
          if (Fe(t.slice(36, 40)) !== Js)
            throw new Error("ICC profile: missing signature");
          if (
            (function su(e) {
              return e.length < vs + 4;
            })(t)
          )
            return r;
          const s = e.getUint32(128);
          let u = 132;
          for (let l = 0; l < s; l++) {
            if (uu(t, u)) return r;
            const f = E(e, u, 4),
              a = e.getUint32(u + 4),
              p = e.getUint32(u + 8);
            if (a > t.length) return r;
            const m = E(e, a, 4);
            if (m === qs) {
              const S = e.getUint32(a + 8);
              if (S > p) return r;
              se(r, f, Fe(t.slice(a + 12, a + S + 11)));
            } else if (m === ws) {
              const S = e.getUint32(a + 8),
                O = e.getUint32(a + 12);
              let D = a + 16;
              const R = [];
              for (let B = 0; B < S; B++) {
                const k = E(e, D + 0, 2),
                  Ce = E(e, D + 2, 2),
                  Ue = e.getUint32(D + 4),
                  be = e.getUint32(D + 8),
                  ye = ue(e, a + be, Ue);
                (R.push({ languageCode: k, countryCode: Ce, text: ye }),
                  (D += O));
              }
              if (1 === S) se(r, f, R[0].text);
              else {
                const B = {};
                for (let k = 0; k < R.length; k++)
                  B[`${R[k].languageCode}-${R[k].countryCode}`] = R[k].text;
                se(r, f, B);
              }
            } else
              m === Qs
                ? se(r, f, Fe(t.slice(a + 8, a + p - 7)))
                : m === Vs && se(r, f, Fe(t.slice(a + 8, a + 12)));
            u += 12;
          }
          return r;
        }
        function Fe(e) {
          return String.fromCharCode.apply(null, new Uint8Array(e));
        }
        function se(e, t, n) {
          Un[t]
            ? (e[Un[t].name] = { value: n, description: n })
            : (e[t] = { value: n, description: n });
        }
        const cu = {
          read: function fu(e, t, n, r, i) {
            let o = J(e, "canon", t, t + n, r, i);
            return (
              o.ShotInfo &&
                ((o = I(
                  {},
                  o,
                  (function au(e) {
                    const t = {};
                    return (
                      void 0 !== e[27] &&
                        (t.AutoRotate = {
                          value: e[27],
                          description: lu(e[27]),
                        }),
                      t
                    );
                  })(o.ShotInfo.value),
                )),
                delete o.ShotInfo),
              o
            );
          },
          SHOT_INFO_AUTO_ROTATE: 27,
        };
        function lu(e) {
          return 0 === e
            ? "None"
            : 1 === e
              ? "Rotate 90 CW"
              : 2 === e
                ? "Rotate 180"
                : 3 === e
                  ? "Rotate 270 CW"
                  : "Unknown";
        }
        const du = {
          read: function pu(e, t) {
            return {
              "Image Width": gu(e, t),
              "Image Height": mu(e, t),
              "Bit Depth": Eu(e, t),
              "Color Type": Su(e, t),
              Compression: xu(e, t),
              Filter: _u(e, t),
              Interlace: Iu(e, t),
            };
          },
        };
        function gu(e, t) {
          if (t + 0 + 4 > e.byteLength) return;
          const i = c.getLongAt(e, t);
          return { value: i, description: `${i}px` };
        }
        function mu(e, t) {
          if (t + 4 + 4 > e.byteLength) return;
          const i = c.getLongAt(e, t + 4);
          return { value: i, description: `${i}px` };
        }
        function Eu(e, t) {
          if (t + 8 + 1 > e.byteLength) return;
          const i = c.getByteAt(e, t + 8);
          return { value: i, description: `${i}` };
        }
        function Su(e, t) {
          if (t + 9 + 1 > e.byteLength) return;
          const o = c.getByteAt(e, t + 9);
          return {
            value: o,
            description:
              {
                0: "Grayscale",
                2: "RGB",
                3: "Palette",
                4: "Grayscale with Alpha",
                6: "RGB with Alpha",
              }[o] || "Unknown",
          };
        }
        function xu(e, t) {
          if (t + 10 + 1 > e.byteLength) return;
          const i = c.getByteAt(e, t + 10);
          return {
            value: i,
            description: 0 === i ? "Deflate/Inflate" : "Unknown",
          };
        }
        function _u(e, t) {
          if (t + 11 + 1 > e.byteLength) return;
          const i = c.getByteAt(e, t + 11);
          return { value: i, description: 0 === i ? "Adaptive" : "Unknown" };
        }
        function Iu(e, t) {
          if (t + 12 + 1 > e.byteLength) return;
          const o = c.getByteAt(e, t + 12);
          return {
            value: o,
            description:
              { 0: "Noninterlaced", 1: "Adam7 Interlace" }[o] || "Unknown",
          };
        }
        const hu = {
            read: function Pu(e, t, n, r) {
              const i = {},
                o = [];
              for (let s = 0; s < t.length; s++) {
                const { offset: u, length: l, type: f } = t[s],
                  a = Cu(e, u, l, f, n);
                if (a instanceof Promise)
                  o.push(
                    a.then(({ name: p, value: m, description: S }) => {
                      try {
                        if (g.USE_EXIF && Dn(p, m))
                          return { __exif: nn.read(Mn(m), Au, r).tags };
                        if (g.USE_IPTC && Ln(p, m))
                          return { __iptc: We.read(Mn(m), 0, r) };
                        if (p && !Dn(p, m) && !Ln(p, m))
                          return { [p]: { value: m, description: S } };
                      } catch {}
                      return {};
                    }),
                  );
                else {
                  const { name: p, value: m, description: S } = a;
                  p && (i[p] = { value: m, description: S });
                }
              }
              return {
                readTags: i,
                readTagsPromise: o.length > 0 ? Promise.all(o) : void 0,
              };
            },
          },
          Qe = "STATE_KEYWORD",
          Ve = "STATE_COMPRESSION",
          et = "STATE_LANG",
          Nn = "STATE_TRANSLATED_KEYWORD",
          tt = "STATE_TEXT",
          Tu = 1,
          Fu = 1,
          Au = 6;
        function Cu(e, t, n, r, i) {
          const o = [],
            s = [],
            u = [];
          let l,
            f = Qe,
            a = fe;
          for (let m = 0; m < n && t + m < e.byteLength; m++) {
            if (f === Ve) {
              ((a = Uu({ type: r, dataView: e, offset: t + m })),
                r === v && (m += Tu),
                (f = Rn(r, f)));
              continue;
            }
            if (f === tt) {
              l = new DataView(e.buffer.slice(t + m, t + n));
              break;
            }
            const S = e.getUint8(t + m);
            0 === S
              ? (f = Rn(r, f))
              : f === Qe
                ? o.push(S)
                : f === et
                  ? s.push(S)
                  : f === Nn && u.push(S);
          }
          if (a !== fe && !i) return {};
          const p = at(
            l,
            a,
            (function bu(e) {
              return e === Ge || e === de ? "latin1" : "utf-8";
            })(r),
          );
          return p instanceof Promise
            ? p
                .then((m) => nt(m, r, s, o))
                .catch(() =>
                  nt("<text using unknown compression>".split(""), r, s, o),
                )
            : nt(p, r, s, o);
        }
        function Uu({ type: e, dataView: t, offset: n }) {
          if (e === v) {
            if (t.getUint8(n) === Fu) return t.getUint8(n + 1);
          } else if (e === de) return t.getUint8(n);
          return fe;
        }
        function Rn(e, t) {
          return t === Qe && [v, de].includes(e)
            ? Ve
            : t === Ve
              ? e === v
                ? et
                : tt
              : t === et
                ? Nn
                : tt;
        }
        function nt(e, t, n, r) {
          const i = (function Ou(e) {
            return e instanceof DataView ? E(e, 0, e.byteLength) : e;
          })(e);
          return {
            name: yu(t, n, r),
            value: i,
            description: t === v ? Nu(e) : i,
          };
        }
        function yu(e, t, n) {
          const r = w(n);
          return e === Ge || 0 === t.length ? r : `${r} (${w(t)})`;
        }
        function Nu(e) {
          return on.decode("UTF-8", e);
        }
        function Dn(e, t) {
          return (
            "raw profile type exif" === e.toLowerCase() &&
            "exif" === t.substring(1, 5)
          );
        }
        function Ln(e, t) {
          return (
            "raw profile type iptc" === e.toLowerCase() &&
            "iptc" === t.substring(1, 5)
          );
        }
        function Mn(e) {
          return (function Ru(e) {
            const t = new DataView(new ArrayBuffer(e.length / 2));
            for (let n = 0; n < e.length; n += 2)
              t.setUint8(n / 2, parseInt(e.substring(n, n + 2), 16));
            return t;
          })(
            e.match(/\n(exif|iptc)\n\s*\d+\n([\s\S]*)$/)[2].replace(/\n/g, ""),
          );
        }
        const Du = {
          read: function Lu(e, t) {
            const n = {};
            for (let r = 0; r < t.length; r++) {
              const i = c.getLongAt(e, t[r] + Q),
                o = E(e, t[r] + X, M);
              o === yt
                ? ((n["Pixels Per Unit X"] = Mu(e, t[r], i)),
                  (n["Pixels Per Unit Y"] = Bu(e, t[r], i)),
                  (n["Pixel Units"] = Gu(e, t[r], i)))
                : o === Ot && (n["Modify Date"] = ku(e, t[r], i));
            }
            return n;
          },
        };
        function Mu(e, t, n) {
          if (!Pe(e, t, n, 0, 4)) return;
          const o = c.getLongAt(e, t + b + 0);
          return { value: o, description: "" + o };
        }
        function Bu(e, t, n) {
          if (!Pe(e, t, n, 4, 4)) return;
          const o = c.getLongAt(e, t + b + 4);
          return { value: o, description: "" + o };
        }
        function Gu(e, t, n) {
          if (!Pe(e, t, n, 8, 1)) return;
          const o = c.getByteAt(e, t + b + 8);
          return { value: o, description: 1 === o ? "meters" : "Unknown" };
        }
        function ku(e, t, n) {
          if (!Pe(e, t, n, 0, 7)) return;
          const i = c.getShortAt(e, t + b),
            o = c.getByteAt(e, t + b + 2),
            s = c.getByteAt(e, t + b + 3),
            u = c.getByteAt(e, t + b + 4),
            l = c.getByteAt(e, t + b + 5),
            f = c.getByteAt(e, t + b + 6);
          return {
            value: [i, o, s, u, l, f],
            description: `${te(i, 4)}-${te(o, 2)}-${te(s, 2)} ${te(u, 2)}:${te(l, 2)}:${te(f, 2)}`,
          };
        }
        function Pe(e, t, n, r, i) {
          return r + i <= n && t + b + r + i <= e.byteLength;
        }
        function te(e, t) {
          return `${"0".repeat(t - ("" + e).length)}${e}`;
        }
        const Zu = {
            read: function Yu(e, t) {
              const n = {},
                r = c.getByteAt(e, t);
              return (
                (n.Alpha = (function zu(e) {
                  const t = 16 & e;
                  return { value: t ? 1 : 0, description: t ? "Yes" : "No" };
                })(r)),
                (n.Animation = (function Ku(e) {
                  const t = 2 & e;
                  return { value: t ? 1 : 0, description: t ? "Yes" : "No" };
                })(r)),
                (n.ImageWidth = Bn(e, t + Hu)),
                (n.ImageHeight = Bn(e, t + Xu)),
                n
              );
            },
          },
          Hu = 4,
          Xu = 7;
        function Bn(e, t) {
          const n =
            c.getByteAt(e, t) +
            256 * c.getByteAt(e, t + 1) +
            65536 * c.getByteAt(e, t + 2) +
            1;
          return { value: n, description: n + "px" };
        }
        const Wu = {
          read: function $u(e) {
            return {
              "GIF Version": ju(e),
              "Image Width": vu(e),
              "Image Height": Ju(e),
              "Global Color Map": qu(e),
              "Bits Per Pixel": Qu(e),
              "Color Resolution Depth": wu(e),
            };
          },
        };
        function ju(e) {
          if (6 > e.byteLength) return;
          const r = E(e, 3, 3);
          return { value: r, description: r };
        }
        function vu(e) {
          if (8 > e.byteLength) return;
          const r = e.getUint16(6, !0);
          return { value: r, description: `${r}px` };
        }
        function Ju(e) {
          if (10 > e.byteLength) return;
          const r = e.getUint16(8, !0);
          return { value: r, description: `${r}px` };
        }
        function qu(e) {
          if (11 > e.byteLength) return;
          const i = (128 & e.getUint8(10)) >>> 7;
          return { value: i, description: 1 === i ? "Yes" : "No" };
        }
        function wu(e) {
          if (11 > e.byteLength) return;
          const i = 1 + ((112 & e.getUint8(10)) >>> 4);
          return { value: i, description: `${i} ${1 === i ? "bit" : "bits"}` };
        }
        function Qu(e) {
          if (11 > e.byteLength) return;
          const i = 1 + (7 & e.getUint8(10));
          return { value: i, description: `${i} ${1 === i ? "bit" : "bits"}` };
        }
        const Vu = [6, 7, 99],
          ec = {
            get: function tc(e, t, n) {
              if (
                (function nc(e) {
                  return (
                    e &&
                    (void 0 === e.Compression ||
                      Vu.includes(e.Compression.value)) &&
                    e.JPEGInterchangeFormat &&
                    e.JPEGInterchangeFormat.value &&
                    e.JPEGInterchangeFormatLength &&
                    e.JPEGInterchangeFormatLength.value
                  );
                })(t)
              ) {
                t.type = "image/jpeg";
                const r = n + t.JPEGInterchangeFormat.value;
                ((t.image = e.buffer.slice(
                  r,
                  r + t.JPEGInterchangeFormatLength.value,
                )),
                  ce(t, "base64", function () {
                    return ut(this.image);
                  }));
              }
              return t;
            },
          };
        function Gn(e) {
          ((this.name = "MetadataMissingError"),
            (this.message = e || "No Exif data"),
            (this.stack = new Error().stack));
        }
        Gn.prototype = new Error();
        const kn = { MetadataMissingError: Gn };
        function rt(e, t) {
          return (
            (function pc(e) {
              try {
                return Buffer.isBuffer(e);
              } catch {
                return !1;
              }
            })(e) && (e = new Uint8Array(e).buffer),
            (function Hn(
              e,
              { expanded: t = !1, async: n = !1, includeUnknown: r = !1 } = {
                expanded: !1,
                async: !1,
                includeUnknown: !1,
              },
            ) {
              let i = !1,
                o = {};
              const s = [],
                {
                  fileType: u,
                  fileDataOffset: l,
                  jfifDataOffset: f,
                  tiffHeaderOffset: a,
                  iptcDataOffset: p,
                  xmpChunks: m,
                  iccChunks: S,
                  mpfDataOffset: O,
                  pngHeaderOffset: D,
                  pngTextChunks: R,
                  pngChunkOffsets: B,
                  vp8xChunkOffset: k,
                  gifHeaderOffset: Ce,
                } = Bi.parseAppMarkers(e, n);
              if (
                g.USE_JPEG &&
                g.USE_FILE &&
                (function mc(e) {
                  return void 0 !== e;
                })(l)
              ) {
                i = !0;
                const d = xo.read(e, l);
                t ? (o.file = d) : (o = I({}, o, d));
              }
              if (
                g.USE_JPEG &&
                g.USE_JFIF &&
                (function Ec(e) {
                  return void 0 !== e;
                })(f)
              ) {
                i = !0;
                const d = bo.read(e, f);
                t ? (o.jfif = d) : (o = I({}, o, d));
              }
              if (
                g.USE_EXIF &&
                (function Sc(e) {
                  return void 0 !== e;
                })(a)
              ) {
                i = !0;
                const { tags: d, byteOrder: W } = nn.read(e, a, r);
                if (
                  (d.Thumbnail &&
                    ((o.Thumbnail = d.Thumbnail), delete d.Thumbnail),
                  t
                    ? ((o.exif = d),
                      (function xc(e) {
                        if (e.exif) {
                          if (e.exif.GPSLatitude && e.exif.GPSLatitudeRef)
                            try {
                              ((e.gps = e.gps || {}),
                                (e.gps.Latitude = ae(e.exif.GPSLatitude.value)),
                                "S" === e.exif.GPSLatitudeRef.value.join("") &&
                                  (e.gps.Latitude = -e.gps.Latitude));
                            } catch {}
                          if (e.exif.GPSLongitude && e.exif.GPSLongitudeRef)
                            try {
                              ((e.gps = e.gps || {}),
                                (e.gps.Longitude = ae(
                                  e.exif.GPSLongitude.value,
                                )),
                                "W" === e.exif.GPSLongitudeRef.value.join("") &&
                                  (e.gps.Longitude = -e.gps.Longitude));
                            } catch {}
                          if (e.exif.GPSAltitude && e.exif.GPSAltitudeRef)
                            try {
                              ((e.gps = e.gps || {}),
                                (e.gps.Altitude =
                                  e.exif.GPSAltitude.value[0] /
                                  e.exif.GPSAltitude.value[1]),
                                1 === e.exif.GPSAltitudeRef.value &&
                                  (e.gps.Altitude = -e.gps.Altitude));
                            } catch {}
                        }
                      })(o))
                    : (o = I({}, o, d)),
                  g.USE_TIFF && g.USE_IPTC && d["IPTC-NAA"] && !Xn(p))
                ) {
                  const F = We.read(d["IPTC-NAA"].value, 0, r);
                  t ? (o.iptc = F) : (o = I({}, o, F));
                }
                if (g.USE_TIFF && g.USE_XMP && d.ApplicationNotes && !Yn(m)) {
                  const F = ln.read(w(d.ApplicationNotes.value));
                  t ? (o.xmp = F) : (delete F._raw, (o = I({}, o, F)));
                }
                if (g.USE_PHOTOSHOP && d.ImageSourceData) {
                  const F = Hs.read(d.PhotoshopSettings.value, r);
                  t ? (o.photoshop = F) : (o = I({}, o, F));
                }
                if (g.USE_TIFF && g.USE_ICC && d.ICC_Profile && !zn(S)) {
                  const F = yn.read(d.ICC_Profile.value, [
                    {
                      offset: 0,
                      length: d.ICC_Profile.value.length,
                      chunkNumber: 1,
                      chunksTotal: 1,
                    },
                  ]);
                  t ? (o.icc = F) : (o = I({}, o, F));
                }
                if (
                  g.USE_MAKER_NOTES &&
                  (function _c(e) {
                    return (
                      e.Make &&
                      e.Make.value &&
                      Array.isArray(e.Make.value) &&
                      "Canon" === e.Make.value[0] &&
                      e.MakerNote &&
                      e.MakerNote.__offset
                    );
                  })(d)
                ) {
                  const F = cu.read(e, a, d.MakerNote.__offset, W, r);
                  t ? (o.makerNotes = F) : (o = I({}, o, F));
                }
                d.MakerNote && delete d.MakerNote.__offset;
              }
              if (g.USE_JPEG && g.USE_IPTC && Xn(p)) {
                i = !0;
                const d = We.read(e, p, r);
                t ? (o.iptc = d) : (o = I({}, o, d));
              }
              if (g.USE_XMP && Yn(m)) {
                i = !0;
                const d = ln.read(e, m);
                t ? (o.xmp = d) : (delete d._raw, (o = I({}, o, d)));
              }
              if ((g.USE_JPEG || g.USE_WEBP) && g.USE_ICC && zn(S)) {
                i = !0;
                const d = yn.read(e, S, n);
                d instanceof Promise ? s.push(d.then(be)) : be(d);
              }
              if (
                g.USE_MPF &&
                (function Ic(e) {
                  return void 0 !== e;
                })(O)
              ) {
                i = !0;
                const d = fo.read(e, O, r);
                t ? (o.mpf = d) : (o = I({}, o, d));
              }
              if (
                g.USE_PNG &&
                g.USE_PNG_FILE &&
                (function hc(e) {
                  return void 0 !== e;
                })(D)
              ) {
                i = !0;
                const d = du.read(e, D);
                t
                  ? ((o.png = o.png ? I({}, o.png, d) : d), (o.pngFile = d))
                  : (o = I({}, o, d));
              }
              if (
                g.USE_PNG &&
                (function Tc(e) {
                  return void 0 !== e;
                })(R)
              ) {
                i = !0;
                const { readTags: d, readTagsPromise: W } = hu.read(e, R, n, r);
                (ye(d), W && s.push(W.then((F) => F.forEach(ye))));
              }
              if (
                g.USE_PNG &&
                (function Fc(e) {
                  return void 0 !== e;
                })(B)
              ) {
                i = !0;
                const d = Du.read(e, B);
                t ? (o.png = o.png ? I({}, o.png, d) : d) : (o = I({}, o, d));
              }
              if (
                g.USE_WEBP &&
                (function Ac(e) {
                  return void 0 !== e;
                })(k)
              ) {
                i = !0;
                const d = Zu.read(e, k);
                t
                  ? (o.riff = o.riff ? I({}, o.riff, d) : d)
                  : (o = I({}, o, d));
              }
              if (
                g.USE_GIF &&
                (function Pc(e) {
                  return void 0 !== e;
                })(Ce)
              ) {
                i = !0;
                const d = Wu.read(e, Ce);
                t ? (o.gif = o.gif ? I({}, o.gif, d) : d) : (o = I({}, o, d));
              }
              const Ue =
                (g.USE_JPEG || g.USE_WEBP) &&
                g.USE_EXIF &&
                g.USE_THUMBNAIL &&
                ec.get(e, o.Thumbnail, a);
              if (
                (Ue ? ((i = !0), (o.Thumbnail = Ue)) : delete o.Thumbnail,
                u &&
                  (t
                    ? (o.file || (o.file = {}), (o.file.FileType = u))
                    : (o.FileType = u),
                  (i = !0)),
                !i)
              )
                throw new kn.MetadataMissingError();
              return n ? Promise.all(s).then(() => o) : o;
              function be(d) {
                t ? (o.icc = d) : (o = I({}, o, d));
              }
              function ye(d) {
                if (t) {
                  for (const W of ["exif", "iptc"]) {
                    const F = `__${W}`;
                    d[F] &&
                      ((o[W] = o[W] ? I({}, o.exif, d[F]) : d[F]), delete d[F]);
                  }
                  ((o.png = o.png ? I({}, o.png, d) : d),
                    (o.pngText = o.pngText ? I({}, o.png, d) : d));
                } else
                  ((o = I(
                    {},
                    o,
                    d.__exif ? d.__exif : {},
                    d.__iptc ? d.__iptc : {},
                    d,
                  )),
                    delete o.__exif,
                    delete o.__iptc);
              }
            })(
              (function gc(e) {
                try {
                  return new DataView(e);
                } catch {
                  return new C(e);
                }
              })(e),
              t,
            )
          );
        }
        function Xn(e) {
          return void 0 !== e;
        }
        function Yn(e) {
          return Array.isArray(e) && e.length > 0;
        }
        function zn(e) {
          return Array.isArray(e) && e.length > 0;
        }
        self.addEventListener(
          "message",
          (function () {
            var e = (0, $.A)(function* (t) {
              const { id: n, url: r } = t.data;
              try {
                const i = yield fetch(r);
                if (!i.ok)
                  return void self.postMessage({
                    id: n,
                    error: "Request failed status " + i.status,
                  });
                const o = yield i.arrayBuffer(),
                  s = new Blob([o], { type: i.headers.get("content-type") }),
                  u = URL.createObjectURL(s),
                  l = yield (function Cc(e) {
                    return new Promise((t) => {
                      const n = new FileReader();
                      ((n.onload = () => {
                        const r = n.result;
                        try {
                          var i;
                          const s =
                            null ===
                              (i = (function Zn(e, t = {}) {
                                return (function rc(e) {
                                  return "string" == typeof e;
                                })(e)
                                  ? ((t.async = !0),
                                    (function ic(e, t) {
                                      return /^\w+:\/\//.test(e)
                                        ? typeof fetch < "u"
                                          ? (function oc(
                                              e,
                                              { length: t } = {},
                                            ) {
                                              const n = { method: "GET" };
                                              return (
                                                Number.isInteger(t) &&
                                                  t >= 0 &&
                                                  (n.headers = {
                                                    range: "bytes=0-" + (t - 1),
                                                  }),
                                                fetch(e, n).then((r) =>
                                                  r.arrayBuffer(),
                                                )
                                              );
                                            })(e, t)
                                          : (function sc(
                                              e,
                                              { length: t } = {},
                                            ) {
                                              return new Promise((n, r) => {
                                                const i = {};
                                                (Number.isInteger(t) &&
                                                  t >= 0 &&
                                                  (i.headers = {
                                                    range: "bytes=0-" + (t - 1),
                                                  }),
                                                  (function uc(e) {
                                                    return /^https:\/\//.test(e)
                                                      ? require("https").get
                                                      : require("http").get;
                                                  })(e)(e, i, (s) => {
                                                    if (
                                                      s.statusCode >= 200 &&
                                                      s.statusCode <= 299
                                                    ) {
                                                      const u = [];
                                                      (s.on("data", (l) =>
                                                        u.push(Buffer.from(l)),
                                                      ),
                                                        s.on("error", (l) =>
                                                          r(l),
                                                        ),
                                                        s.on("end", () =>
                                                          n(Buffer.concat(u)),
                                                        ));
                                                    } else
                                                      (r(
                                                        `Could not fetch file: ${s.statusCode} ${s.statusMessage}`,
                                                      ),
                                                        s.resume());
                                                  }).on("error", (s) => r(s)));
                                              });
                                            })(e, t)
                                        : (function cc(e) {
                                              return /^data:[^;,]*(;base64)?,/.test(
                                                e,
                                              );
                                            })(e)
                                          ? Promise.resolve(
                                              (function Kn(e) {
                                                const t = e.substring(
                                                  e.indexOf(",") + 1,
                                                );
                                                if (-1 !== e.indexOf(";base64"))
                                                  return typeof atob < "u"
                                                    ? Uint8Array.from(
                                                        atob(t),
                                                        (r) => r.charCodeAt(0),
                                                      ).buffer
                                                    : typeof Buffer > "u"
                                                      ? void 0
                                                      : typeof Buffer.from < "u"
                                                        ? Buffer.from(
                                                            t,
                                                            "base64",
                                                          )
                                                        : new Buffer(
                                                            t,
                                                            "base64",
                                                          );
                                                const n = decodeURIComponent(t);
                                                return typeof Buffer < "u"
                                                  ? typeof Buffer.from < "u"
                                                    ? Buffer.from(n)
                                                    : new Buffer(n)
                                                  : Uint8Array.from(n, (r) =>
                                                      r.charCodeAt(0),
                                                    ).buffer;
                                              })(e),
                                            )
                                          : (function fc(
                                              e,
                                              { length: t } = {},
                                            ) {
                                              return new Promise((n, r) => {
                                                const i = (function ac() {
                                                  try {
                                                    return require("fs");
                                                  } catch {
                                                    return;
                                                  }
                                                })();
                                                i.open(e, (o, s) => {
                                                  o
                                                    ? r(o)
                                                    : i.stat(e, (u, l) => {
                                                        if (u) r(u);
                                                        else {
                                                          const f = Math.min(
                                                              l.size,
                                                              void 0 !== t
                                                                ? t
                                                                : l.size,
                                                            ),
                                                            a = Buffer.alloc(f);
                                                          i.read(
                                                            s,
                                                            {
                                                              buffer: a,
                                                              length: f,
                                                            },
                                                            (m) => {
                                                              m
                                                                ? r(m)
                                                                : i.close(
                                                                    s,
                                                                    (S) => {
                                                                      (S &&
                                                                        console.warn(
                                                                          `Could not close file ${e}:`,
                                                                          S,
                                                                        ),
                                                                        n(a));
                                                                    },
                                                                  );
                                                            },
                                                          );
                                                        }
                                                      });
                                                });
                                              });
                                            })(e, t);
                                    })(e, t).then((n) => rt(n, t)))
                                  : (function lc(e) {
                                        return (
                                          typeof window < "u" &&
                                          typeof File < "u" &&
                                          e instanceof File
                                        );
                                      })(e)
                                    ? ((t.async = !0),
                                      (function dc(e) {
                                        return new Promise((t, n) => {
                                          const r = new FileReader();
                                          ((r.onload = (i) =>
                                            t(i.target.result)),
                                            (r.onerror = () => n(r.error)),
                                            r.readAsArrayBuffer(e));
                                        });
                                      })(e).then((n) => rt(n, t)))
                                    : rt(e, t);
                              })(r).UserComment) || void 0 === i
                              ? void 0
                              : i.description;
                          if (s)
                            try {
                              const u = JSON.parse(s);
                              if (u.colors) return void t({ colors: u.colors });
                            } catch (u) {
                              console.error(
                                "Failed to parse UserComment as JSON",
                                u,
                              );
                            }
                        } catch (o) {
                          console.error("Failed to read EXIF metadata", o);
                        }
                        t({});
                      }),
                        (n.onerror = () => {
                          (console.error("Failed to read image Blob"), t({}));
                        }),
                        n.readAsArrayBuffer(e));
                    });
                  })(s);
                self.postMessage({ id: n, imageUrl: u, metadata: l });
              } catch (i) {
                self.postMessage({ id: n, error: i.message });
              }
            });
            return function (t) {
              return e.apply(this, arguments);
            };
          })(),
        );
      },
    },
    ot = {};
  function h(_) {
    var P = ot[_];
    if (void 0 !== P) return P.exports;
    var T = (ot[_] = { exports: {} });
    return (it[_](T, T.exports, h), T.exports);
  }
  ((h.m = it),
    (h.x = () => {
      var _ = h.O(void 0, [76], () => h(88578));
      return h.O(_);
    }),
    (_ = []),
    (h.O = (P, T, $, C) => {
      if (!T) {
        var G = 1 / 0;
        for (U = 0; U < _.length; U++) {
          for (var [T, $, C] = _[U], E = !0, N = 0; N < T.length; N++)
            (!1 & C || G >= C) && Object.keys(h.O).every((ce) => h.O[ce](T[N]))
              ? T.splice(N--, 1)
              : ((E = !1), C < G && (G = C));
          if (E) {
            _.splice(U--, 1);
            var ue = $();
            void 0 !== ue && (P = ue);
          }
        }
        return P;
      }
      C = C || 0;
      for (var U = _.length; U > 0 && _[U - 1][2] > C; U--) _[U] = _[U - 1];
      _[U] = [T, $, C];
    }),
    (h.d = (_, P) => {
      for (var T in P)
        h.o(P, T) &&
          !h.o(_, T) &&
          Object.defineProperty(_, T, { enumerable: !0, get: P[T] });
    }),
    (h.f = {}),
    (h.e = (_) =>
      Promise.all(Object.keys(h.f).reduce((P, T) => (h.f[T](_, P), P), []))),
    (h.u = (_) => "common.1bb8089756535934.js"),
    (h.miniCssF = (_) => {}),
    (h.o = (_, P) => Object.prototype.hasOwnProperty.call(_, P)),
    (h.j = 889),
    (() => {
      var _;
      h.tt = () => (
        void 0 === _ &&
          ((_ = { createScriptURL: (P) => P }),
          typeof trustedTypes < "u" &&
            trustedTypes.createPolicy &&
            (_ = trustedTypes.createPolicy("angular#bundler", _))),
        _
      );
    })(),
    (h.tu = (_) => h.tt().createScriptURL(_)),
    (h.p = ""),
    (() => {
      var _ = { 889: 1 };
      h.f.i = (C, U) => {
        _[C] || importScripts(h.tu(h.p + h.u(C)));
      };
      var T = (self.webpackChunkgfn_mall = self.webpackChunkgfn_mall || []),
        $ = T.push.bind(T);
      T.push = (C) => {
        var [U, G, E] = C;
        for (var N in G) h.o(G, N) && (h.m[N] = G[N]);
        for (E && E(h); U.length; ) _[U.pop()] = 1;
        $(C);
      };
    })(),
    (() => {
      var _ = h.x;
      h.x = () => h.e(76).then(_);
    })(),
    h.x());
})();
