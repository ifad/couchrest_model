/* CouchRest::Model Generic Lucene view.
 *
 * This is a <<Poor-Man's Multiline JS File>>
 *
 * Function constraints:
 *   * Double quotes are NOT allowed
 *   * Each statement MUST terminate with a semicolon
 *   * Single-line comments (//) are NOT allowed
 *
 * TODO: better documentation
 */
{
  "_id"     : "_design/lucene",
  "language": "javascript",
  "version" : <%= Date.today.strftime('%Y%m%d01') %>,
  "fulltext": {
    "search": {
      "defaults": { "store": "yes" },
      "index": "
        function(doc) {
          /* Index only CouchRest Model documents skipping
           * ones having the "skip_from_index" property set
           */
          if (!doc['<%= CouchRest::Model::Base.model_type_key %>'] || doc['skip_from_index']) {
            return null;
          }

          var ret = new Document();

          /* Add the given value twice, one with the "default"
           * field name, and one with the key name as field name
           * but with '-' replaced with '_' - as dashed field
           * names aren't allowed when querying Lucene - neither
           * it is the dot. Sigh.
           */
          var add = function (key, val, type) {
            ret.add(val, {'type': type});

            if (key) {
              var field = nesting;
              /* Don't add array indexes to the field name */
              if (!/^[0-9]/.test(key[0]))
                field = field.concat(key.replace(/[:-]/g, '_'));

              /* DEBUG log.info('Indexing ' + val + ' as ' + field);*/
              ret.add(val, {'type': type, 'field': field.join('__')});
            }
          };

          /* Alters the given ISO 8601 date format in a way that
           * SpiderMonkey's Date parsing function likes it.
           *
           *  js> mangle_8601("2011-04-13T17:37:01+02:00")
           *  2011/04/13 17:37:01 +02:00
           */
          var mangle_8601 = function (iso8601) {
            return iso8601.replace(/-/g,'/').replace(/[TZ]/g,' ').replace('+',' +');
          };

          /* Does some magic to infer the field type via
           * the following conventions:
           *
           *  * Anything that ends with "_at" or "_on" is a date string
           *  * Anything that ends with "_timestamp" or "_ts" is a floating
           *    point timestamp, that is a UNIX time() / 1000.0
           *  * Anything that contains "password" is skipped.
           */
          var fuzzy_add = function (key, val) {
            if (/password/.test(key))
              return;

            if (/_(?:at|on)$/.test(key)) {
              add(key, new Date(mangle_8601(val)), 'date');

            } else if (/_(?:timestamp|ts)$/.test(key)) {
              add(key, new Date(val * 1000), 'date');

            } else {
              add(key, val, 'string');

            }
          };

          /* Nested objects stack */
          var nesting = [];
          var index = function (obj) {
            if (obj === null)
              return;

            for (var key in obj) {
              var val = obj[key];

              if (!val) continue;

              switch (typeof val) {
              case 'object':
                nesting.push (key);
                index(val); /* Recurse */
                nesting.pop ();
                break;

              case 'boolean':
                add(key, val ? 1 : 0, 'int');
                break;

              case 'number':
                add(key, val, 'float');
                break;

              case 'string':
                fuzzy_add(key, val);
                break;
              }
            }
          };

          index(doc);

          if (doc._attachments) {
            for (var i in doc._attachments) {
              ret.attachment('default', i);
            }
          }

          return ret;
        }
      "
    }
  }
}
