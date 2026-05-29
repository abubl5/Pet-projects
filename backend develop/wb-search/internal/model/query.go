package model

import "strings"

var punctuationReplacer = strings.NewReplacer(
	",", " ",
	".", " ",
	";", " ",
	":", " ",
	"!", " ",
	"?", " ",
	"\n", " ",
	"\t", " ",
)

func NormalizeQuery(query string) string {
	query = strings.TrimSpace(query)
	query = strings.ToLower(query)
	query = punctuationReplacer.Replace(query)
	query = strings.Join(strings.Fields(query), " ")

	return query
}
