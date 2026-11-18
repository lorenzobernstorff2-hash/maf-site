"""Testes da comparação site × Gaby (tests/paridade.py). Rodar: python3 tests/test_paridade.py"""
import copy
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paridade

PRICING = """
export const MINIMO_TABELA_ATACADO = 20;
export const PARCELA_MINIMA_CENTAVOS = 20_000;
export const PISO_ATACADO_BPS = 7_000;
export const FRETE_TEXTO = 'frete não incluso';
export const PRAZO_DIAS: Record<ItemPrazo, number> = {
  // comentário no meio
  white_label: 5,
  private_catalogo: 60,
};
const UNIDADE_PRAZO: Record<ItemPrazo, string> = {
  white_label: 'dias',
  private_catalogo: 'dias úteis',
};
"""
CONDICOES = {
    "gaby": {
        "MINIMO_TABELA_ATACADO": 20,
        "PARCELA_MINIMA_CENTAVOS": 20000,
        "PRAZO_DIAS": {"white_label": 5, "private_catalogo": 60},
        "UNIDADE_PRAZO": {"white_label": "dias", "private_catalogo": "dias úteis"},
    },
    "ignoradas": {"PISO_ATACADO_BPS": "interna", "FRETE_TEXTO": "texto"},
}


class Comparar(unittest.TestCase):
    def test_igual_nao_acusa_nada(self):
        self.assertEqual(paridade.comparar(PRICING, CONDICOES), [])

    def test_numero_com_sublinhado_e_lido_inteiro(self):
        self.assertEqual(paridade.ler_pricing(PRICING)["PARCELA_MINIMA_CENTAVOS"], 20000)

    def test_valor_diferente_acusa_os_dois_lados(self):
        c = copy.deepcopy(CONDICOES)
        c["gaby"]["MINIMO_TABELA_ATACADO"] = 30
        falhas = paridade.comparar(PRICING, c)
        self.assertEqual(len(falhas), 1)
        self.assertIn("MINIMO_TABELA_ATACADO", falhas[0])
        self.assertIn("20", falhas[0])
        self.assertIn("30", falhas[0])

    def test_prazo_diferente_acusa(self):
        c = copy.deepcopy(CONDICOES)
        c["gaby"]["PRAZO_DIAS"]["private_catalogo"] = 45
        self.assertIn("PRAZO_DIAS.private_catalogo", paridade.comparar(PRICING, c)[0])

    def test_unidade_do_prazo_diferente_acusa(self):
        c = copy.deepcopy(CONDICOES)
        c["gaby"]["UNIDADE_PRAZO"]["white_label"] = "dias úteis"
        self.assertIn("UNIDADE_PRAZO.white_label", paridade.comparar(PRICING, c)[0])

    def test_constante_nova_na_gaby_acusa(self):
        novo = PRICING + "export const VETORIZACAO_LOGO_CENTAVOS = 3_000;\n"
        falhas = paridade.comparar(novo, CONDICOES)
        self.assertEqual(len(falhas), 1)
        self.assertIn("VETORIZACAO_LOGO_CENTAVOS", falhas[0])

    def test_prazo_novo_na_gaby_acusa(self):
        novo = PRICING.replace("private_catalogo: 60,", "private_catalogo: 60,\n  personalizacao_dtf: 15,")
        self.assertIn("PRAZO_DIAS.personalizacao_dtf", paridade.comparar(novo, CONDICOES)[0])

    def test_constante_que_sumiu_da_gaby_acusa(self):
        sem = PRICING.replace("export const MINIMO_TABELA_ATACADO = 20;", "")
        self.assertIn("MINIMO_TABELA_ATACADO", paridade.comparar(sem, CONDICOES)[0])

    def test_ignorada_nao_acusa(self):
        self.assertNotIn("PISO_ATACADO_BPS", " ".join(paridade.comparar(PRICING, CONDICOES)))

    def test_constante_exportada_em_formato_que_nao_sei_ler_acusa(self):
        for linha in ("export const TAXA_NOVA = 5 * 100;", "export const TAXA_NOVA = 1.5;",
                      "export const TAXA_NOVA = -5;", "  export  const TAXA_NOVA = 5 as const;",
                      "export const TAXA_NOVA = 'texto';"):
            falhas = paridade.comparar(PRICING + linha + "\n", CONDICOES)
            self.assertEqual(len(falhas), 1, linha)
            self.assertIn("TAXA_NOVA", falhas[0])
            self.assertIn("formato", falhas[0])


class Avisos(unittest.TestCase):
    def test_preco_do_erp_velho_avisa(self):
        avisos = paridade.avisos_de_idade({"erp": {"conferido_em": "2026-01-01"}}, hoje="2026-03-01")
        self.assertEqual(len(avisos), 1)

    def test_preco_do_erp_recente_nao_avisa(self):
        self.assertEqual(paridade.avisos_de_idade({"erp": {"conferido_em": "2026-02-20"}}, hoje="2026-03-01"), [])

    def test_sem_data_avisa(self):
        self.assertEqual(len(paridade.avisos_de_idade({"erp": {}}, hoje="2026-03-01")), 1)


if __name__ == "__main__":
    unittest.main()
